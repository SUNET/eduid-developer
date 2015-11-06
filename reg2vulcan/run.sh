#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#


. ../common.sh

name="reg2vulcan"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

HostIP=172.17.42.1

# No expiry at the moment, seems that refreshes are not always performed?
# Possibly this is reg2vulcan timing out on the etcd connection.
#
#    -ttl 120 \
#    -ttl-refresh 90 \

$sudo docker rm $name
docker run --rm=true \
    --name=${name} \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    -h $(hostname) \
    docker.sunet.se/eduid/${name}
