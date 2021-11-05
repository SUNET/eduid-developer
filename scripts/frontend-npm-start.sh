#!/bin/bash
#
# This script will run npm start for the eduid frontend code. It is intended to run inside a docker container.

set -e
set -x

test -d /src/eduid-front/build || {
    echo "$0: Not running in a docker container (/src/eduid/front-build not found)"
    exit 1
}

#unset LD_LIBRARY_PATH
node --version
npm --version

cd /src/eduid-front

ls -l

npm install
npm start

