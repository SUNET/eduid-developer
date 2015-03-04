#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

. ../common.sh

name="mongodb"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p data/db log/mongodb

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

$sudo docker rm $name
$sudo docker run --rm=true \
    --name ${name} \
    --hostname ${name} \
    --dns=172.17.42.1 \
    -v $PWD/log:/var/log/mongodb \
    -v $PWD/data:/data \
    -v $PWD/etc:/opt/eduid/etc \
    -v $PWD/db-scripts:/opt/eduid/db-scripts \
    $DOCKERARGS \
    -i -t \
    docker.sunet.se/eduid/${name}
