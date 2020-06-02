#!/bin/bash

set -e
set -x

export DEBIAN_FRONTEND noninteractive

# Install packages
/bin/sed -i s/archive.ubuntu.com/se.archive.ubuntu.com/g /etc/apt/sources.list
apt-get update -y
apt-get install -y git \
  apt-transport-https \
  build-essential \
  curl \
  gnupg-agent \
  software-properties-common \
  python-pip \
  bash-completion \
  bridge-utils
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get update -y
apt-get install -y docker-ce \
  docker-ce-cli \
  containerd.io
apt-get clean

# Networking
ip addr del 172.16.10.10/24 dev enp0s8
docker network create \
    --driver bridge \
    --subnet=172.16.10.0/24 \
    --gateway=172.16.10.10 \
    --opt "com.docker.network.bridge.name"="br-eduid" \
    eduid_dev
brctl addif br-eduid enp0s8

# Setup environment
usermod -aG docker vagrant
pip install pyyaml python-etcd
ln -svf /opt/src/eduid-front /opt/eduid-developer/sources/
ln -svf /opt/src/eduid-html /opt/eduid-developer/sources/
