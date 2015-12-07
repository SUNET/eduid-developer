#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#


. ../common.sh

name="nagios3"

mkdir -p log run

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

$sudo docker rm $name
docker run --rm=true \
    --name=${name} \
    -v $PWD/log:/var/log/nagios3 \
    -v $PWD/run:/var/run/nagios3 \
    -h $(hostname) \
    docker.sunet.se/eduid/${name}
