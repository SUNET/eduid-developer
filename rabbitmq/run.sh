#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

name="rabbitmq"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc

if [ $($sudo docker ps | awk '{print $NF}' | grep -qx $name) ]; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

$sudo docker rm $name
$sudo docker run --rm=true \
    --name ${name} \
    --hostname ${name} \
    --dns=172.17.42.1 \
    -v $PWD/log:/var/log/rabbitmq \
    -v $PWD/etc:/etc/rabbitmq \
    $DOCKERARGS \
    docker.sunet.se/eduid/rabbitmq
