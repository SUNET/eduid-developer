#!/bin/sh

if [ ! -f eduid/compose.yml ]; then
    echo "Run $0 from the eduid-developer top level directory"
    exit 1
fi

./bin/docker-compose -f eduid/compose.yml rm -s -f
