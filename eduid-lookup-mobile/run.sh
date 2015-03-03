#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

name="eduid-lookup-mobile"


# Check if running on mac
if [ $(uname) = "Darwin" ]; then

    #Get ip of dns
    dnsip=$(ipconfig getifaddr en0)

    # Check so the boot2docker vm is running
    if [ $(boot2docker status) != "running" ]; then
        boot2docker start
        $(boot2docker shellinit)
    fi
else
    dnsip=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
    if [ $(id -u) -ne 0 ]; then
        sudo="sudo"
    fi
fi

mkdir -p log etc

srcdir=$(echo ~/work/NORDUnet/${name})
if [ -d "${srcdir}" ]; then
    # map developers local source copy into /opt/eduid/src and set PYTHONPATH accordingly
    src_volume="-v ${srcdir}:/opt/eduid/src --env=PYTHONPATH=/opt/eduid/src"
fi

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
    $src_volume \
    -v $PWD/log:/var/log/eduid \
    -v $PWD/etc:/opt/eduid/etc \
    --env=EDUID_LOOKUP_MOBILE_CONFIG=/opt/eduid/etc/ \
    $DOCKERARGS \
    docker.sunet.se/eduid/${name}

    #--link mongodb:mongodb \
    #--link rabbitmq:rabbitmq \
