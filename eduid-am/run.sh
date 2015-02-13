#!/bin/bash
#
# To debug your container:
#
#   DOCKERARGS="--entrypoint /bin/bash -i -t" bash -x ./run.sh
#

. ../common.sh

name="eduid-am"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

mkdir -p log etc src

host_src_path="$(echo $(get_code_path))"
guest_src_path="/opt/eduid/src"

srcdir="${host_src_path}/${name}"
if [ -d "${srcdir}" ]; then
    # map developers local source copy into /opt/eduid/src and set PYTHONPATH accordingly
    src_volume="-v ${srcdir}:${guest_src_path}/${name}"
    env_vars="--env=PYTHONPATH=${guest_src_path}/${name}"

    dashboard_amp_dir="${host_src_path}/eduid-dashboard-amp"
    if [ -d "${dashboard_amp_dir}" ]; then
        src_volume+=" -v ${dashboard_amp_dir}:${guest_src_path}/eduid-dashboard-amp"
        env_vars+=":${guest_src_path}/eduid-dashboard-amp"
    fi
    
    signup_amp_dir="${host_src_path}/eduid-signup-amp"
    if [ -d "${signup_amp_dir}" ]; then
        src_volume+=" -v ${signup_amp_dir}:${guest_src_path}/eduid-signup-amp"
        env_vars+=":${guest_src_path}/eduid-signup-amp"
    fi
  
    src_volume+=" ${env_vars}"
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
    -v $PWD/log:/var/log/eduid \
    $src_volume \
    $DOCKERARGS \
    docker.sunet.se/eduid/${name}
