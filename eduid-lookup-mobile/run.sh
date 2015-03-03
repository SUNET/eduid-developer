#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

. ../common.sh

name="eduid-lookup-mobile"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc

src_params="$(get_developer_params ${name})"
echo "Source parameters: ${src_params}"

if ${sudo} docker ps | awk '{print $NF}' | grep -qx $name; then
    echo "$0: Docker container with name $name already running. Press enter to restart it, or ctrl+c to abort."
    read foo
    ${sudo} docker kill $name
fi

${sudo} docker rm $name
${sudo} docker run --rm=true \
    --name ${name} \
    --hostname ${name} \
    --dns=172.17.42.1 \
    $src_params \
    -v $PWD/log:/var/log/eduid \
    -v $PWD/etc:/opt/eduid/eduid-lookup-mobile/etc \
    --env=EDUID_LOOKUP_MOBILE_CONFIG=/opt/eduid/eduid-lookup-mobile/etc \
    $DOCKERARGS \
    docker.sunet.se/eduid/${name}
