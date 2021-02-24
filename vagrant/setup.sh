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
  bridge-utils \
  python3-pip
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

# Setup environment
usermod -aG docker vagrant
pip3 install pyyaml python-etcd

