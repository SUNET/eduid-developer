#!/bin/bash

set -e
set -x

export DEBIAN_FRONTEND noninteractive

# Upgrade packages
apt-get update -y
apt full-upgrade -y
apt-get clean

# Fix networking
ip addr del 172.16.10.10/24 dev enp0s8
brctl addif br-eduid enp0s8
