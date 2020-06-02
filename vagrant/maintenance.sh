#!/bin/bash

set -e
set -x

export DEBIAN_FRONTEND noninteractive

# Upgrade packages
apt-get update -y
apt full-upgrade -y
apt-get autoremove -y
apt-get clean

# Link to sources if missing
ln -svf /opt/src/eduid-front /opt/eduid-developer/sources/
ln -svf /opt/src/eduid-html /opt/eduid-developer/sources/

# Docker maintenance
docker system prune -f

# Fix networking
ip addr del 172.16.10.10/24 dev enp0s8
docker network create \
    --driver bridge \
    --subnet=172.16.10.0/24 \
    --gateway=172.16.10.10 \
    --opt "com.docker.network.bridge.name"="br-eduid" \
    eduid_dev
brctl addif br-eduid enp0s8
