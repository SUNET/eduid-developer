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
    -v $PWD/log:/var/log/eduid \
    -v $PWD/data:/data \
    -v $PWD/etc:/opt/eduid/etc \
    $DOCKERARGS \
    docker.sunet.se/eduid/mongodb
