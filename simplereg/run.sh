#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#


. ../common.sh

name="simplereg"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

src_params="$(get_developer_params simple-registrator simplereg)"
echo "Source parameters: ${src_params}"

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

HostIP=$(docker0_ipaddress)

    #--volume=/etc/passwd:/etc/passwd:ro \
    #--volume=/etc/group:/etc/group:ro \

$sudo docker rm $name
docker run --rm=true \
    --name=${name} \
    --dns=$(docker0_ipaddress) \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    -e REGISTRATOR_ETCD=1 \
    -e REGISTRATOR_DEBUG=0 \
    -e ETCD_HOST="etcd.docker" \
    -h $(hostname) \
    $src_params \
    $DOCKERARGS \
    docker.sunet.se/eduid/${name} -- --debug

