#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

. ../common.sh

name="pypiserver"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

$sudo docker rm $name
$sudo docker run --rm=true \
    --name ${name} \
    --hostname ${name} \
    --dns=$(docker0_ipaddress) \
    -v $PWD/etc:/opt/eduid/pypiserver/etc:ro \
    -v $PWD/log:/var/log/pypiserver \
    -v $PWD/packages:/opt/eduid/pypiserver/packages:ro \
    $DOCKERARGS \
    -i -t \
    docker.sunet.se/eduid/${name}
