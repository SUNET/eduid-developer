#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir run log etc

$sudo docker run --rm=true \
    --name signup \
    -v $PWD/etc:/opt/eduid/etc \
    -v $PWD/run:/opt/eduid/run \
    -v $PWD/log:/var/log/eduid \
    --link mongodb:mongodb \
    --link rabbitmq:rabbitmq \
    $DOCKERARGS \
    docker.sunet.se/eduid/eduid-signup
