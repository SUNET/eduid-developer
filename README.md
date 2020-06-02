Setting up a development environment on your own machine
========================================================


Building
--------

All containers should be built by ci.sunet.se and will be pulled when starting the environment.

If you need to build docker containers use the Dockerfiles in the repository
eduid-dockerfiles.

    $ git clone git@github.com:SUNET/eduid-dockerfiles.git
    $ cd eduid-dockerfiles
    $ ./build eduid-email


Running
-------

Start all the containers with the Makefile in this repository.

The first time it will ask you for sudo rights to be able to write in your /etc/hosts. You also need to write the configuration to etcd before anything can start, see etcd configuration below.

##### Linux Docker environment:

    $ make start

##### Other OS Vagrant environment:

Install Vagrant and Virtualbox. Complete the Vagrant Getting started guide until you see that "vagrant up" works.

https://www.virtualbox.org/
https://www.vagrantup.com/intro/getting-started/up


Create a file name __vagrant.yml__ in the repository root.

    local_paths:
      eduid_front: '/path/to/eduid-front'
      eduid_html: '/path/to/eduid-html'

Then run:

    $ make vagrant_up  (only needed once per session)
    $ make vagrant_start

To connect to the vagrant vm:

    $ make vagrant_ssh


Stopping
--------

##### Linux Docker environment

    $ make stop


##### Other OS Vagrant environment:

    $ make vagrant_down


etcd configuration
------------------

  The microservices and dashboard js uses etcd to get their configuration.

  To update the configuration edit etcd/conf.yaml and run `make update_etcd`.

Logging
-------

All logs from webapps are kept in a shared data volume called eduidlogdata.

For a quick tail -F run, ex:

    $ ./bin/tailf signup

To get a shell with mounted log files:

    $ make show_logs


Authentication
--------------

Turq (a mock HTTP server) is used to fake 'OK' responses to all calls to the
VCCS authentication backend.

Services
--------

  http://signup.eduid.docker:8080/
  http://dashboard.eduid.docker:8080/
  http://html.eduid.docker/
  http://support.eduid.docker:8080/

  http://turq.eduid.docker:13085/+turq/
  http://rabbitmq.eduid.docker:15672/   (login: admin/password)

  mongodb://mongodb.eduid.docker
  redis://redis.eduid.docker
  etcd://etcd.eduid.docker

Live code reloads
-----------------

For the different eduid components I've tried to set up the containers to
'mount' a developers local source tree in /opt/eduid/src which will then
also be inserted into the PYTHONPATH. The current mechanism for finding the
source on the developers machine is through an environment variable
`EDUID_SRC_PATH` (and defaults to ~/work/NORDUnet). Just be careful to not
use '~' in the `EDUID_SRC_PATH`, since it may be expanded as a different user.

Both the main package and its eduid dependencies will be mounted for each 
container (as long as they are present at `EDUID_SRC_PATH`).


Signup
------

The confirmation code will be available in the log file
TODO (the whole confirmation
e-mail will be logged instead of sent using SMTP).


Local Docker vs Vagrant
-----------------------

If you want to run both you need to reset your networking before switching.

###### Docker:

    $ docker networking rm eduid_dev

###### Vagrant (Virtualbox):

Open Virtualbox and go to File -> Host Network Manager and remove the network 172.16.10.0/24.
