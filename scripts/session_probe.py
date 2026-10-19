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

    config                               the session settings the apps in this container use
    keys                                 list session-looking keys in the session db
    create [eppn]                        make a session (optionally logged in as eppn)
    read    <cookie>                     decrypted session data + ttl
    raw     <cookie> [needle]            the shape of the stored (encrypted) value; with <needle>,
                                         whether that string appears anywhere in the stored value.
                                         The stored value itself is never printed: it is session data
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

Redis host, app secret, session ttl and cookie name are read from the config the webapp container
itself mounts ($EDUID_CONFIG_YAML, namespace $EDUID_CONFIG_NS), so nothing is duplicated from
config/config.yaml here.

This probe mints authenticated sessions for any eppn and prints the decrypted contents of any cookie,
so it refuses to run unless the configuration it finds says `environment: dev`, and refuses when it
can read no configuration at all. EDUID_PROBE_I_KNOW_THIS_IS_DEV=1 overrides that for a dev stack
that keeps its config somewhere else.

The environment variables EDUID_REDIS_HOST and EDUID_SECRET override the values read from config.

Path syntax is dotted: "common.preferred_language", "_csrft_", "idp.pending_requests.abc.used".
"""

from __future__ import annotations

import json
import os
import secrets
import sys
from pathlib import Path
from typing import Any

import redis
from eduid.common.config.base import EduIDBaseAppConfig, RedisConfig
from eduid.webapp.common.session.meta import SessionMeta
from eduid.webapp.common.session.redis_session import SessionManager

_session_id_len = 64  # hex chars of a 256 bit session id


def _app_config() -> dict[str, Any]:
    """
    The merged configuration of the webapp whose container this probe runs in, as a plain dict.

    The same traversal and common-namespace merge as eduid.common.config.parsers.load_config, without
    instantiating any app config model (that wants to write to /dev/shm as the app user).
    """
    yaml_file = os.environ.get("EDUID_CONFIG_YAML", "/opt/eduid/config.yaml")
    if not yaml_file or not Path(yaml_file).is_file():
        return {}
    from eduid.common.config.parsers.yaml_parser import YamlConfigParser

    app_ns = os.environ.get("EDUID_CONFIG_NS", "/eduid/webapp/idp")
    common_ns = os.environ.get("EDUID_CONFIG_COMMON_NS") or f"{app_ns.rsplit('/', 1)[0]}/common/"
    parser = YamlConfigParser(path=Path(yaml_file))
    try:
        merged = dict(parser.read_configuration(common_ns))
        merged.update(parser.read_configuration(app_ns))
    except KeyError:
        return {}
    return merged


_CFG = _app_config()
ENVIRONMENT = str(_CFG.get("environment") or "")
REDIS_HOST = os.environ.get("EDUID_REDIS_HOST") or str(_CFG.get("redis_config", {}).get("host") or "")
SECRET = os.environ.get("EDUID_SECRET") or str(_CFG.get("secret_key") or "")
SESSION_COOKIE_NAME = str(_CFG.get("session_cookie_name") or "sessid")
# SessionFactory uses ttl = 2 * flask.permanent_session_lifetime
TTL = int(os.environ.get("EDUID_SESSION_TTL") or 2 * int(_CFG.get("permanent_session_lifetime") or 14400))


def _refusal() -> str | None:
    """Why this probe will not run here, or None when it accepts the environment."""
    if os.environ.get("EDUID_PROBE_I_KNOW_THIS_IS_DEV") == "1":
        return None
    if not _CFG:
        return (
            "no webapp configuration found (set EDUID_CONFIG_YAML, or EDUID_PROBE_I_KNOW_THIS_IS_DEV=1 "
            "for a dev stack that keeps its config elsewhere)"
        )
    if ENVIRONMENT != "dev":
        return f"this probe only runs against environment: dev, this configuration says {ENVIRONMENT!r}"
    if not SECRET:
        return "the configuration has no secret_key"
    if not REDIS_HOST:
        return "the configuration has no redis_config.host"
    return None


def cmd_config(_: list[str]) -> dict:
    """What the apps in this container do with sessions. Reports no session data and no secret."""
    fields = EduIDBaseAppConfig.model_fields
    return {
        "environment": ENVIRONMENT,
        "session_cookie_name": SESSION_COOKIE_NAME,
        "session_ttl": TTL,
        "redis_host": REDIS_HOST,
        "session_safe_to_lose_paths": list(
            _CFG.get("session_safe_to_lose_paths") or fields["session_safe_to_lose_paths"].default
        ),
        "session_fatal_other_writer_paths": list(
            _CFG.get("session_fatal_other_writer_paths") or fields["session_fatal_other_writer_paths"].default
        ),
        "safe_to_lose_from_config": "session_safe_to_lose_paths" in _CFG,
    }


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
    # SCAN, not KEYS: this is the db 0 that the apps are serving requests from, and there is no
    # reason to enumerate the non-session keys of that instance into a JSON blob either
    sessions = [
        k.decode()
        for k in _conn().scan_iter(match="*", count=500)
        if len(k) == _session_id_len and all(c in b"0123456789abcdef" for c in k)
    ]
    return {"keys": sorted(sessions), "count": len(sessions)}


def cmd_create(args: list[str]) -> dict:
    eppn = args[0] if args else ""
    meta = SessionMeta.new(app_secret=SECRET)
    sess = _manager().get_session(meta=meta, new=True)
    if eppn:
        sess["common"] = {"eppn": eppn, "is_logged_in": True, "login_source": "idp", "preferred_language": "en"}
    csrf = secrets.token_hex(20)  # unguessable, like the tokens the apps generate
    sess["_csrft_"] = csrf
    sess.commit()
    return {
        "cookie": meta.cookie_val,
        "session_id": meta.session_id,
        "csrf": csrf,
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
    """
    The shape of the stored value, and whether a caller-named string occurs anywhere in it.

    The stored value is session data: it is scanned here rather than handed to the caller, so that a
    test can check the whole value without the suite printing part of it.
    """
    meta = _meta(args[0])
    raw = _conn().get(meta.session_id)
    if raw is None:
        return {"exists": False, "session_id": meta.session_id, "envelope_keys": None, "length": 0}
    text = raw.decode("utf-8", "replace")
    try:
        envelope_keys: list[str] | None = sorted(json.loads(text).keys())
    except ValueError:
        envelope_keys = None
    res: dict = {
        "exists": True,
        "session_id": meta.session_id,
        "envelope_keys": envelope_keys,
        "length": len(text),
        # ciphertext framing, not session data; enough to see which envelope version is in use
        "prefix": text[:16],
    }
    if len(args) > 1 and args[1]:
        res["found"] = args[1] in text
    return res


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
    "config": cmd_config,
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
    if sys.argv[1] != "config":
        # minting or reading sessions of an environment we cannot identify is not a dev convenience
        refusal = _refusal()
        if refusal:
            print(json.dumps({"error": f"session_probe refuses to run: {refusal}"}))
            return 3
    try:
        result = COMMANDS[sys.argv[1]](args)
    except Exception as exc:  # noqa: BLE001 - report to the caller as JSON
        print(json.dumps({"error": f"{type(exc).__name__}: {exc}"}))
        return 1
    print(json.dumps(result, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
