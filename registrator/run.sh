#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#


. ../common.sh

name="registrator"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

HostIP=172.17.42.1

$sudo docker rm $name
docker run --rm=true \
    --name=registrator \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    -h $(hostname) \
    docker.sunet.se/library/registrator:v7-dev \
    -ttl 120 \
    -ttl-refresh 90 \
    -ip $HostIP \
    -internal \
    etcd://${HostIP}:4001/services
