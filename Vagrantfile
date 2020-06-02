# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Box / OS
VAGRANT_BOX = 'ubuntu/bionic64'
VM_NAME = 'eduid-dev-vagrant'


settings = YAML.load_file 'vagrant.yml'
eduid_front_path = settings['local_paths']['eduid_front']
eduid_html_path = settings['local_paths']['eduid_html']


Vagrant.configure(2) do |config|

    required_plugins = %w( vagrant-vbguest vagrant-disksize )
    _retry = false
    required_plugins.each do |plugin|
       unless Vagrant.has_plugin? plugin
         system "vagrant plugin install #{plugin}"
      _retry=true
    end
  end

  if (_retry)
      exec "vagrant " + ARGV.join(' ')
   end

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

  # Disk size
  config.disksize.size = "20GB"

  # Networking
  config.vm.network "private_network", ip: "172.16.10.10"

  # Sync folder
  config.vm.synced_folder eduid_front_path, '/opt/src/eduid-front/'
  config.vm.synced_folder eduid_html_path, '/opt/src/eduid-html/'
  config.vm.synced_folder '.', '/opt/eduid-developer/'

  #Setup VM
  config.vm.provision :shell, path: "vagrant/setup.sh"
  config.vm.provision :shell, path: "vagrant/maintenance.sh", run: 'always'

end
