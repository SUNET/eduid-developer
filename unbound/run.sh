#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash" bash -x ./run.sh
#

ipaddress_docker0=$(ifconfig docker0 | grep "inet addr:" | awk '{print $2}' | awk -F : '{print $2}')

. ../common.sh

name="unbound"

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
    --net host \
    -v $PWD/etc:/etc/unbound \
    -v /etc/unbound/unbound_control.key:/etc/unbound/unbound_control.key:ro \
    -v /etc/unbound/unbound_control.pem:/etc/unbound/unbound_control.pem:ro \
    -v /etc/unbound/unbound_server.key:/etc/unbound/unbound_server.key:ro \
    -v /etc/unbound/unbound_server.pem:/etc/unbound/unbound_server.pem:ro \
    -v $PWD/log:/var/log \
    -v /dev/random:/dev/random:ro \
    -v /dev/urandom:/dev/urandom:ro \
    -e "unbound_interface=${ipaddress_docker0}" \
    $src_params \
    $DOCKERARGS \
    -i -t \
    docker.sunet.se/eduid/${name}
