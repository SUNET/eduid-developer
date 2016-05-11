#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash" bash -x ./run.sh
#

. ../common.sh

name="eduid-authn"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc src run

src_params="$(get_developer_params "eduid-webapp")"
echo "Source parameters: ${src_params}"

if $sudo docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    $sudo docker kill $name
fi

$sudo docker rm $name
$sudo docker run --rm=true \
    --name authn \
    --hostname authn \
    --net=${DOCKER_NETWORK} \
    -v $PWD/etc:/opt/eduid/${name}/etc:ro \
    -v $PWD/run:/opt/eduid/${name}/run \
    -v $PWD/log:/var/log/eduid \
    $src_params \
    $DOCKERARGS \
    -i -t \
    docker.sunet.se/eduid/${name}:latest
