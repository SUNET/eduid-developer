#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#


. ../common.sh

name="vulcand"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

HostIP=172.17.42.1

echo ""
echo "*** Access etcd like this:"
echo ""
echo "    docker exec -i -t etcd /etcdctl member list"
echo ""

$sudo docker rm $name
$sudo docker run --rm=true \
    --name ${name} \
    --net host \
    docker.sunet.se/library/vulcand:latest \
    -etcd=http://${HostIP}:4001 \
    -logSeverity=DEBUG
