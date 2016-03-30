#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#


. ../common.sh

name="etcd"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

HostIP=$(docker0_ipaddress)

echo ""
echo "*** Access etcd like this:"
echo ""
echo "    docker exec -i -t etcd /etcdctl member list"
echo ""

$sudo docker rm $name
$sudo docker run \
    --name ${name} \
    --hostname ${name} \
    --dns=$(docker0_ipaddress) \
    -p 4001:4001 -p 2379:2379 \
    docker.sunet.se/library/etcd:v2.2.5 \
    -name etcd \
    -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
    -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001
