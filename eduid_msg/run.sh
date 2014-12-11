#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

$sudo docker run --rm=true \
    --name eduid_msg \
    -v $PWD/etc:/opt/eduid/etc \
    -v $PWD/log:/var/log/eduid \
    --link mongodb:mongodb \
    --link rabbitmq:rabbitmq \
    $DOCKERARGS \
    docker.sunet.se/eduid/eduid-msg
