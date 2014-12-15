#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p data/db log/mongodb

$sudo docker run --rm=true \
    --name mongodb \
    --dns=172.17.42.1 \
    -v $PWD/log:/var/log/mongodb \
    -v $PWD/data:/data \
    -v $PWD/etc:/opt/eduid/etc \
    $DOCKERARGS \
    docker.sunet.se/eduid/mongodb
