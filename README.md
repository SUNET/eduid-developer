Setting up a development environment on your own machine
========================================================


Building
--------

All containers should be built by ci.nordu.net and will be pulled when starting the environment.

If you need to build docker containers use the Dockerfiles in the repository
eduid-dockerfiles.

    # git clone git@github.com:SUNET/eduid-dockerfiles.git
    # cd eduid-dockerfiles
    # ./build rabbitmq


Running
-------

Start all the containers with the start.sh file in this repository.

Linux Docker environment:

    # make start

Other OS Vagrant environment:

    # make vagrant_start
    # vagrant ssh
    # cd /opt/eduid-developer
    # make start

The first time it will ask you for sudo rights to be able to write in your /etc/hosts.

etcd configuration
------------------

  The microservices and dashboard js uses etcd to get their configuration.

  To update the configuration edit etcd/conf.yaml and run `make update_etcd`.

Logging
-------

    TODO

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

Docker:

    # docker networking rm eduid_dev

Vagrant (Virtualbox):

    # vboxmanage hostonlyif remove TODO

You can also open Virtualbox and go to File -> Host Network Manager and remove the network 172.16.10.0/24.
