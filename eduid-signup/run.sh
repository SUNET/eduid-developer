#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

name="signup"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p run log etc

srcdir=$(echo ~/work/NORDUnet/eduid-${name})
if [ -d "${srcdir}" ]; then
    # map developers local source copy into /opt/eduid/src and set PYTHONPATH accordingly
    src_volume="-v ${srcdir}:/opt/eduid/src --env=PYTHONPATH=/opt/eduid/src"
fi

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
    -v $PWD/etc:/opt/eduid/etc \
    -v $PWD/run:/opt/eduid/run \
    -v $PWD/log:/var/log/eduid \
    $src_volume \
    $DOCKERARGS \
    docker.sunet.se/eduid/eduid-${name}
