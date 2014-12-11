#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc

$sudo docker run --rm=true \
    --name rabbitmq \
    -v $PWD/log:/var/log/rabbitmq \
    -v $PWD/etc:/etc/rabbitmq \
    $DOCKERARGS \
    docker.sunet.se/eduid/rabbitmq
