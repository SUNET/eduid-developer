# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Box / OS
VAGRANT_BOX = 'hashicorp/bionic64'
VM_NAME = 'eduid-dev-vagrant'


settings = YAML.load_file 'vagrant.yml'
eduid_front_path = settings['local_paths']['eduid_front']
eduid_html_path = settings['local_paths']['eduid_html']


Vagrant.configure(2) do |config|

  # Vagrant box from Hashicorp
  config.vm.box = VAGRANT_BOX

  # Actual machine name
  config.vm.hostname = VM_NAME

  # Set VM name in Virtualbox
  config.vm.provider "virtualbox" do |v|
    v.name = VM_NAME
    v.memory = 4096
    v.cpus = 2
    # Change the network adapter type and promiscuous mode
    v.customize ['modifyvm', :id, '--nictype1', 'Am79C973']
    v.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
    v.customize ['modifyvm', :id, '--nictype2', 'Am79C973']
    v.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
  end

  # Networking
  config.vm.network "private_network", ip: "172.16.10.10"
  #config.vm.network "private_network", ip: "172.16.10.10",
  #  virtualbox__intnet: "br-eduid"

  # Sync folder
  config.vm.synced_folder eduid_front_path, '/opt/src/eduid-front/'
  config.vm.synced_folder eduid_html_path, '/opt/src/eduid-html/'
  config.vm.synced_folder '.', '/opt/eduid-developer/'

  #Setup VM
  config.vm.provision :shell, path: "vagrant/setup.sh"

end
