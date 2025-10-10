#!/bin/sh
DOCKER=$(which docker)

if [ ! -f eduid/compose.yml ]; then
    echo "Run $0 from the eduid-developer top level directory"
    exit 1
fi

$DOCKER compose -f eduid/compose.yml down
$DOCKER compose -f eduid/compose.yml rm -s -f
