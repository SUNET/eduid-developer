#!/bin/bash

set -e
set -x

export DEBIAN_FRONTEND noninteractive

# Upgrade packages
apt-get update -y
apt full-upgrade -y
apt-get autoremove -y
apt-get clean

# Docker maintenance
docker system prune -f

# Create the docker network inside the VM. This network will be bridged to the
# host (the host running the VM), so that the individual containers running on
# the docker network can be accessed from the host.
#
# The host has IP 172.16.10.1, and the VM has 172.16.10.10. We assign static IPs
# to everything that should be reachable from the host in the range 172.16.10.128/25,
# so let docker assign IPs to containers that don't have a static IP in the range
# 172.16.10.32/27.
#
# Address plan:
#
#  172.16.10.1        host running virtualbox
#  172.16.10.10       the VM
#  172.16.10.32-63    docker assigned container IPs
#  172.16.10.128-255  manually assigned container IPs
#
docker network create \
    --driver bridge \
    --subnet=172.16.10.0/24 \
    --ip-range=172.16.10.32/27 \
    --gateway=172.16.10.10 \
    --opt "com.docker.network.bridge.name"="br-eduid" \
    eduid_dev

brctl addif br-eduid enp0s8
# The IP 172.16.10.10 is now set on both enp0s8 and br-eduid.
# Remove it from enp0s8 to make container access work from the VM.
ip addr del 172.16.10.10/24 dev enp0s8

# Link to sources if missing
ln -svf /opt/src/eduid-front /opt/eduid-developer/sources/
ln -svf /opt/src/eduid-html /opt/eduid-developer/sources/

# Create tls keys and certificats
cd /opt/eduid-developer/pki/ && /opt/eduid-developer/pki/create_pki.sh
