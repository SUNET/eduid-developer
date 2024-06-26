#!/usr/bin/env python3

import argparse
import json
import logging
import sys
from dataclasses import dataclass
from pprint import pformat
from typing import Callable, Optional, Any

import requests

logger = logging.getLogger(__name__)


@dataclass
class ScimApi:
    session: requests.Session
    url: str
    token: Optional[str] = None


def get_scimapi_jwt(s: requests.Session, url: str, key: str, cert: str, key_name: str, scope: str) -> str:
    grant_req = {
        "access_token": [
            {
                "flags": ["bearer"],
                "access": [{"scope": scope, "type": "scim-api"}],
            },
        ],
        "client": {
            "key": key_name,
        },
    }
    continue_resp = s.post(url=f"{url}/transaction", cert=(cert, key), json=grant_req)
    if continue_resp.status_code != 200:
        logger.error(f"auth server error: {continue_resp.text}")
        sys.exit(1)
    return continue_resp.json()["access_token"]["value"]


def scim_request(
    func: Callable,
    url: str,
    data: Optional[dict] = None,
    headers: Optional[dict] = None,
    token: Optional[str] = None,
    verify: bool = True,
) -> Optional[dict[str, Any]]:
    if not headers:
        headers = {"content-type": "application/scim+json"}
    if token is not None:
        logger.debug(f"Using Authorization {token}")
        headers["Authorization"] = f"Bearer {token}"
    logger.debug(f"API URL: {url}")
    r = _make_request(func, url, data, headers, verify)

    if not r:
        return None
    try:
        response = r.json()
    except json.JSONDecodeError:
        return {"status_code": r.status_code}
    logger.debug(f"Response:\n{pformat(response, width=120)}")
    return response


def _make_request(
    func: Callable,
    url: str,
    data: Optional[dict] = None,
    headers: Optional[dict] = None,
    verify: bool = True,
) -> Optional[requests.Response]:
    r = func(url, json=data, headers=headers, verify=verify)
    logger.debug(f"Response from server: {r}\n{r.text}")

    if r.status_code not in [200, 201, 204]:
        try:
            logger.error(
                f"Failure parsed_response ({r.status_code}) received from server:\n"
                f"{json.dumps(r.json(), sort_keys=True, indent=4)}"
            )
        except Exception:
            logger.error(f"Error {r} received from server: {r.text}")
        return None
    return r


def search_user(api: ScimApi, external_id: str) -> Optional[str]:
    logger.debug(f"Searching for user with filter {filter}")
    query = {
        "schemas": ["urn:ietf:params:scim:api:messages:2.0:SearchRequest"],
        "filter": f'externalId eq "{external_id}"',
        "startIndex": 1,
        "count": 1,
    }

    logger.debug(f"Sending user search query:\n{json.dumps(query, sort_keys=True, indent=4)}")
    res = scim_request(api.session.post, f"{api.url}/Users/.search", data=query, token=api.token)
    logger.debug(f"User search result:\n{json.dumps(res, sort_keys=True, indent=4)}\n")
    if res is None:
        return None
    resources = res.get("Resources", [])
    if len(resources) == 0:
        return None
    return resources[0]["id"]


def search_group(api: ScimApi, display_name: str) -> Optional[str]:
    logger.debug(f"Searching for group with filter {filter}")
    query = {
        "schemas": ["urn:ietf:params:scim:api:messages:2.0:SearchRequest"],
        "filter": f'displayName eq "{display_name}"',
        "startIndex": 1,
        "count": 10,
    }

    logger.debug(f"Sending group search query:\n{json.dumps(query, sort_keys=True, indent=4)}")
    res = scim_request(api.session.post, f"{api.url}/Groups/.search", data=query, token=api.token)
    logger.debug(f"Group search result:\n{json.dumps(res, sort_keys=True, indent=4)}\n")
    if res is None:
        return None
    resources = res.get("Resources", [])
    if len(resources) == 0:
        return None
    return resources[0]["id"]


def create_user(api: ScimApi, external_id: str, scope: str, given_name: str, surname: str, mfa_stepup: bool) -> Optional[str]:
    logger.info(f"Creating user with externalId {external_id}")
    unscoped_external_id, eduid_scope = external_id.split("@")
    query = {
        "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User", "https://scim.eduid.se/schema/nutid/user/v1"],
        "externalId": external_id,
        "name": {
            "givenName": given_name,
            "familyName": surname
        },
        "https://scim.eduid.se/schema/nutid/user/v1": {
            "profiles": {"connectIdp": {"attributes": {"eduPersonPrincipalName": f"{unscoped_external_id}@{scope}"}}},
            "linked_accounts": [
                {"issuer": eduid_scope, "value": external_id, "parameters": {"mfa_stepup": mfa_stepup}}
            ],
        },
    }
    logger.debug(f"Sending user create query:\n{pformat(json.dumps(query, sort_keys=True, indent=4))}")
    res = scim_request(api.session.post, f"{api.url}/Users/", data=query, token=api.token)
    logger.debug(f"User create result:\n{json.dumps(res, sort_keys=True, indent=4)}\n")
    if res is None:
        return None
    return res["id"]


def create_group(api: ScimApi, display_name: str) -> Optional[str]:
    logger.info(f"Creating group with displayName {display_name}")
    query = {"schemas": ["urn:ietf:params:scim:schemas:core:2.0:Group"], "displayName": display_name, "members": []}
    logger.debug(f"Sending group create query:\n{pformat(json.dumps(query, sort_keys=True, indent=4))}")
    res = scim_request(api.session.post, f"{api.url}/Groups/", data=query, token=api.token)
    logger.debug(f"Group create result:\n{json.dumps(res, sort_keys=True, indent=4)}\n")
    if res is None:
        return None
    return res["id"]


def get_group_resource(api: ScimApi, scim_id: str) -> Optional[dict[str, Any]]:
    logger.debug(f"Fetching SCIM group resource {scim_id}")

    return scim_request(api.session.get, f"{api.url}/Groups/{scim_id}", token=api.token)

def get_user_resource(api: ScimApi, scim_id: str) -> Optional[dict[str, Any]]:
    logger.debug(f"Fetching SCIM user resource {scim_id}")

    return scim_request(api.session.get, f"{api.url}/Users/{scim_id}", token=api.token)

def add_user_to_group(api: ScimApi, group_scim_id: Optional[str], user_scim_id: Optional[str], user_external_id: str) -> bool:
    if group_scim_id is None or user_scim_id is None:
        return False
    scim_group = get_group_resource(api, group_scim_id)
    if not scim_group:
        logger.error(f"Group with scim ID {group_scim_id} not found")
        return False

    meta = scim_group.pop("meta")
    members = scim_group.get("members", [])
    for member in members:
        if member["value"] == user_scim_id:
            logger.info(f"User {user_external_id} already in group {scim_group['displayName']}")
            return False
    members.append({"$ref": f"{api.url}/Users/{user_scim_id}", "value": user_scim_id, "display": user_external_id})
    scim_group["members"] = members

    headers = {"content-type": "application/scim+json", "if-match": meta["version"]}

    logger.debug(f"Updating SCIM group resource {group_scim_id}:\n{json.dumps(scim_group, sort_keys=True, indent=4)}\n")
    res = scim_request(
        api.session.put, f"{api.url}/Groups/{group_scim_id}", data=scim_group, headers=headers, token=api.token
    )
    logger.debug(f"Update result:\n{json.dumps(res, sort_keys=True, indent=4)}")
    return True

def show_user(api: ScimApi, user_id: Optional[str]) -> None:
    if user_id is None:
        logger.info("No user found")
    res = scim_request(api.session.get, f"{api.url}/Users/{user_id}", token=api.token)
    logger.info(f"User result:\n{json.dumps(res, sort_keys=True, indent=4)}")

def delete_user(api: ScimApi, user_id: Optional[str], user_version: str) -> None:
    if user_id is None:
        logger.info("No user found")
    headers = {"content-type": "application/scim+json", "if-match": user_version}
    res = scim_request(api.session.delete, f"{api.url}/Users/{user_id}", headers=headers, token=api.token)
    logger.info(f"Delete result:\n{res}")

def main(args: argparse.Namespace):
    s = requests.Session()
    s.verify = not args.insecure
    logger.debug(f"Verifying TLS connections: {s.verify}")
    jwt = get_scimapi_jwt(
        s=s, url=args.auth_url, key=args.key, cert=args.cert, key_name=args.key_name, scope=args.scope
    )
    scim_api = ScimApi(session=s, url=args.scim_url, token=jwt)
    # lookup user id
    user_id = search_user(api=scim_api, external_id=args.external_id)
    if args.show:
        show_user(api=scim_api, user_id=user_id)
        sys.exit(0)
    if args.delete:
        delete_user(api=scim_api, user_id=user_id, user_version=args.user_version)
        sys.exit(0)
    if args.create_user and user_id is None:
        user_id = create_user(api=scim_api, external_id=args.external_id, scope=args.scope, given_name=args.user_given_name, surname=args.user_surname, mfa_stepup=args.mfa_stepup)
    # lookup group id
    group_id = search_group(api=scim_api, display_name=args.group)
    if group_id is None:
        # create the group
        group_id = create_group(api=scim_api, display_name=args.group)
    # add user to group
    if add_user_to_group(api=scim_api, group_scim_id=group_id, user_scim_id=user_id, user_external_id=args.external_id):
        logger.info(f"Added user {args.external_id} to group {args.group}")
        sys.exit(0)
    logger.info(f"User not added to group {args.group}")


def _config_logger(args: argparse.Namespace, progname: str):
    # This is the root log level
    level = logging.INFO
    if args.debug:
        level = logging.DEBUG
    logging.basicConfig(level=level, stream=sys.stderr, format="%(asctime)s: %(name)s: %(levelname)s %(message)s")
    logger.name = progname
    # If stderr is not a TTY, change the log level of the StreamHandler (stream = sys.stderr above) to WARNING
    if not sys.stderr.isatty() and not args.debug:
        for this_h in logging.getLogger("").handlers:
            this_h.setLevel(logging.WARNING)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bootstrap a user as admin for an organization")
    parser.add_argument("--key", help="private key", type=str, required=True)
    parser.add_argument("--cert", help="public certificate", type=str, required=True)
    parser.add_argument("--key-name", help="GNAP key name (as stated in auth server config)", type=str, required=True)
    parser.add_argument("--external-id", help="users scoped eduID eppn", type=str, required=True)
    parser.add_argument("--scope", help="organizations scope", type=str, required=True)
    parser.add_argument("--auth-url", help="auth server url", type=str, required=True)
    parser.add_argument("--scim-url", help="scim api server url", type=str, required=True)
    parser.add_argument(
        "--group", default="Organization Managers", help="display name of group to add user to", type=str
    )
    parser.add_argument("--create-user", default=False, action="store_true", help="create user in scim db if missing")
    parser.add_argument("--user-given-name", type=str, default="Not set", required=False, help="Set users given name")
    parser.add_argument("--user-surname", type=str, default="Not set", required=False, help="Set users surname")
    parser.add_argument(
        "--mfa-stepup", default=False, action="store_true", help="if user is created, enable mfa step up"
    )
    parser.add_argument("--insecure", default=False, action="store_true", help="do not validate tls connections")
    parser.add_argument("--show", default=False, action="store_true", help="show user with supplied external-id")
    parser.add_argument("--delete", default=False, action="store_true", help="delete user with supplied external-id")
    parser.add_argument("--user-version", type=str, required=False, help="use with --delete to make sure the correct user is removed")
    parser.add_argument("--debug", default=False, action="store_true", help="enable debug logging")
    args = parser.parse_args()
    _config_logger(args=args, progname="bootstrap_scim_admin")
    main(args=args)

