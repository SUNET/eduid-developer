#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash" bash -x ./run.sh
#

name="oathaead"
oath_yhsm_device="/dev/ttyACM0"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc

src_params="$(get_developer_params eduid-api)"
echo "Source parameters: ${src_params}"

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
    -v $PWD/etc:/opt/eduid/eduid-oathaead/etc \
    -v $PWD/log:/var/log/eduid \
    --env "eduid_name=eduid-oathaead" \
    --device=${oath_yhsm_device}:${oath_yhsm_device}:rw \
    $src_params \
    $DOCKERARGS \
    -i -t \
    docker.sunet.se/eduid/eduid-api
