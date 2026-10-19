#!/usr/bin/env python3
"""
Inspect (and, for the concurrency tests, write) eduID sessions in the dev stack's Redis.

The browser-facing tests in playwright_session_handling.js can only see cookies and HTTP responses.
This probe runs *inside* a webapp container so it can use the same code the apps use
(eduid.webapp.common.session) to look at the decrypted backend session, and to act as a *second
writer* against the same Redis key - which is how the tests reproduce a sibling request
concurrently committing (or logging out) while a request is in flight.

Usage (from the eduid-developer checkout):

    docker cp scripts/session_probe.py eduid-idp-1:/tmp/session_probe.py
    docker exec -i -e PYTHONPATH=/opt/eduid/sources eduid-idp-1 \
        /opt/eduid/webapp/bin/python3 /tmp/session_probe.py <command> ...

Commands (all print one JSON object on stdout):

    keys                                 list session-looking keys in the session db
    create [eppn]                        make a session (optionally logged in as eppn)
    read    <cookie>                     decrypted session data + ttl
    raw     <cookie>                     the stored (encrypted) value, truncated
    ttl     <cookie>                     remaining ttl in seconds (-2 = key missing)
    exists  <cookie>                     does the backend session exist
    expire  <cookie> <seconds>           shorten the ttl (simulate an about-to-expire session)
    delete  <cookie>                     delete the backend session key
    setpath <cookie> <path> <json>       as another writer: set a dotted key path
    delpath <cookie> <path>              as another writer: delete a dotted key path
    setns   <cookie> <ns> <json>         as another writer: replace/delete a whole namespace
    regen   <cookie>                     as another writer: replace the session generation marker
                                         (what a logout/reset does), leaving every other path as is
    reset   <cookie>                     as another writer: behave like EduidSession.reset():
                                         drop all namespaces, keep the csrf token, new generation

The environment variables EDUID_REDIS_HOST and EDUID_SECRET override the (dev stack defaults)
redis.eduid_dev / "supersecretkey" from config/config.yaml.

Path syntax is dotted: "common.preferred_language", "_csrft_", "idp.pending_requests.abc.used".
"""

from __future__ import annotations

import json
import os
import sys

import redis
from eduid.common.config.base import RedisConfig
from eduid.webapp.common.session.meta import SessionMeta
from eduid.webapp.common.session.redis_session import SessionManager

REDIS_HOST = os.environ.get("EDUID_REDIS_HOST", "redis.eduid_dev")
SECRET = os.environ.get("EDUID_SECRET", "supersecretkey")
# SessionFactory uses ttl = 2 * flask.permanent_session_lifetime
TTL = int(os.environ.get("EDUID_SESSION_TTL", "28800"))

_session_id_len = 64  # hex chars of a 256 bit session id


def _conn() -> redis.StrictRedis:
    return redis.StrictRedis(host=REDIS_HOST)


def _manager() -> SessionManager:
    return SessionManager(RedisConfig(host=REDIS_HOST), app_secret=SECRET, ttl=TTL)


def _meta(cookie: str) -> SessionMeta:
    return SessionMeta.from_cookie(cookie, app_secret=SECRET)


def _load(cookie: str):
    """Load the existing backend session for a cookie, as the app would."""
    return _manager().get_session(meta=_meta(cookie), new=False)


def _split(path: str) -> list[str]:
    parts = [p for p in path.split(".") if p]
    if not parts:
        raise ValueError(f"invalid path {path!r}")
    return parts


def _set_path(sess, path: str, value: object) -> None:
    """Set a dotted path in the live session data (nested dicts are the stored objects)."""
    parts = _split(path)
    if len(parts) == 1:
        sess[parts[0]] = value
        return
    node = sess.get(parts[0])
    if not isinstance(node, dict):
        node = {}
        sess[parts[0]] = node
    for part in parts[1:-1]:
        nxt = node.get(part)
        if not isinstance(nxt, dict):
            nxt = {}
            node[part] = nxt
        node = nxt
    node[parts[-1]] = value


def _del_path(sess, path: str) -> None:
    """Delete a dotted path from the live session data."""
    parts = _split(path)
    if len(parts) == 1:
        if parts[0] not in sess:
            raise KeyError(path)
        del sess[parts[0]]
        return
    node = sess.get(parts[0])
    if not isinstance(node, dict):
        raise KeyError(path)
    for part in parts[1:-1]:
        nxt = node.get(part)
        if not isinstance(nxt, dict):
            raise KeyError(path)
        node = nxt
    if parts[-1] not in node:
        raise KeyError(path)
    del node[parts[-1]]


def cmd_keys(_: list[str]) -> dict:
    keys = [k.decode() for k in _conn().keys("*")]
    sessions = [k for k in keys if len(k) == _session_id_len and all(c in "0123456789abcdef" for c in k)]
    return {"keys": sorted(sessions), "other_keys": sorted(set(keys) - set(sessions)), "count": len(sessions)}


def cmd_create(args: list[str]) -> dict:
    eppn = args[0] if args else ""
    meta = SessionMeta.new(app_secret=SECRET)
    sess = _manager().get_session(meta=meta, new=True)
    if eppn:
        sess["common"] = {"eppn": eppn, "is_logged_in": True, "login_source": "idp", "preferred_language": "en"}
    sess["_csrft_"] = "probe-csrf-token"
    sess.commit()
    return {
        "cookie": meta.cookie_val,
        "session_id": meta.session_id,
        "generation": getattr(sess, "generation", None),
        "ttl": _conn().ttl(meta.session_id),
    }


def cmd_read(args: list[str]) -> dict:
    meta = _meta(args[0])
    conn = _conn()
    ttl = conn.ttl(meta.session_id)
    if ttl < 0:
        return {"exists": False, "session_id": meta.session_id, "ttl": ttl, "data": None}
    sess = _load(args[0])
    return {
        "exists": True,
        "session_id": meta.session_id,
        "ttl": ttl,
        "generation": getattr(sess, "generation", None),
        "data": sess.to_dict(),
    }


def cmd_raw(args: list[str]) -> dict:
    meta = _meta(args[0])
    raw = _conn().get(meta.session_id)
    if raw is None:
        return {"exists": False, "session_id": meta.session_id, "raw": None}
    text = raw.decode("utf-8", "replace")
    return {"exists": True, "session_id": meta.session_id, "raw": text[:120], "length": len(text)}


def cmd_ttl(args: list[str]) -> dict:
    meta = _meta(args[0])
    return {"session_id": meta.session_id, "ttl": _conn().ttl(meta.session_id)}


def cmd_exists(args: list[str]) -> dict:
    meta = _meta(args[0])
    return {"session_id": meta.session_id, "exists": bool(_conn().exists(meta.session_id))}


def cmd_expire(args: list[str]) -> dict:
    meta = _meta(args[0])
    secs = int(args[1])
    conn = _conn()
    conn.expire(meta.session_id, secs)
    return {"session_id": meta.session_id, "ttl": conn.ttl(meta.session_id)}


def cmd_delete(args: list[str]) -> dict:
    meta = _meta(args[0])
    return {"session_id": meta.session_id, "deleted": _conn().delete(meta.session_id), "ttl": _conn().ttl(meta.session_id)}


def _regen(sess) -> None:
    if not hasattr(sess, "reset_generation"):
        raise RuntimeError("this build has no session generations (webapp/common/session/redis_session.py)")
    sess.reset_generation()


def _reset_like_the_app(sess) -> None:
    """What EduidSession.reset(keep_csrf=True) leaves behind: no namespaces, same csrf token, new generation."""
    csrf = sess.get("_csrft_")
    for key in list(sess.keys()):
        del sess[key]
    if csrf is not None:
        sess["_csrft_"] = csrf
    _regen(sess)


def _rewrite(cookie: str, mutate) -> dict:
    """Load the session, mutate it and commit it back - ie. behave like another writer."""
    sess = _load(cookie)
    # deep copy: to_dict() is shallow and the mutation below changes the nested dicts in place
    before = json.loads(json.dumps(sess.to_dict(), default=str))
    mutate(sess)
    sess.commit()
    after = _load(cookie).to_dict()
    meta = _meta(cookie)
    return {
        "session_id": meta.session_id,
        "ttl": _conn().ttl(meta.session_id),
        "before": before,
        "after": after,
    }


def cmd_setpath(args: list[str]) -> dict:
    path, value = args[1], json.loads(args[2])
    return _rewrite(args[0], lambda sess: _set_path(sess, path, value))


def cmd_delpath(args: list[str]) -> dict:
    return _rewrite(args[0], lambda sess: _del_path(sess, args[1]))


def cmd_regen(args: list[str]) -> dict:
    """Change only the session generation marker, the way reset()/clear() do."""
    return _rewrite(args[0], _regen)


def cmd_reset(args: list[str]) -> dict:
    """Act like a sibling logout: reset() the session contents and bump the generation."""
    return _rewrite(args[0], _reset_like_the_app)


def cmd_setns(args: list[str]) -> dict:
    """Replace (or, with null, remove) a whole session namespace, e.g. 'common'."""
    ns, value = args[1], (None if args[2] in ("null", "none") else json.loads(args[2]))

    def mutate(sess) -> None:
        if value is None:
            if ns not in sess:
                raise KeyError(ns)
            del sess[ns]
        else:
            sess[ns] = value

    return _rewrite(args[0], mutate)


COMMANDS = {
    "keys": cmd_keys,
    "create": cmd_create,
    "read": cmd_read,
    "raw": cmd_raw,
    "ttl": cmd_ttl,
    "exists": cmd_exists,
    "expire": cmd_expire,
    "delete": cmd_delete,
    "setpath": cmd_setpath,
    "delpath": cmd_delpath,
    "regen": cmd_regen,
    "reset": cmd_reset,
    "setns": cmd_setns,
}


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(f"usage: session_probe.py {{{'|'.join(sorted(COMMANDS))}}} ...", file=sys.stderr)
        return 2
    args = sys.argv[2:]
    try:
        result = COMMANDS[sys.argv[1]](args)
    except Exception as exc:  # noqa: BLE001 - report to the caller as JSON
        print(json.dumps({"error": f"{type(exc).__name__}: {exc}"}))
        return 1
    print(json.dumps(result, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
