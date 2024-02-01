#!/bin/bash
#
# This script will npm build the eduid frontend code. It is intended to run inside a docker container.

set -e
set -x

test -d /src/eduid-managed-accounts/dist || {
    echo "$0: Not running in a docker container (/src/eduid-managed-accounts/dist not found)"
    exit 1
}

#unset LD_LIBRARY_PATH
node --version
npm --version

cd /src/eduid-managed-accounts

ls -l

# set safe dir to be able to create revision.txt
git config --global --add safe.directory /src/eduid-managed-accounts
make clean
make build

cat >/src/eduid-managed-accounts/dist/config.js <<EOL
const managed_accounts_config = {
  auth_server_url: "https://api.eduid.docker/auth/",
  scim_server_url: "https://api.eduid.docker/scim",
  redirect_url: "https://managed-accounts.eduid.docker/callback",
};
EOL
