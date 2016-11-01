Setting up a development environment on your own machine
========================================================


Building
--------

Build docker containers using the Dockerfiles in the repository
eduid-dockerfiles.

    # git clone git@github.com:SUNET/eduid-dockerfiles.git
    # cd eduid-dockerfiles
    # ./build rabbitmq
    # ./build mongodb
    # ./build turq

The other containers should be built by ci.nordu.net and will be pulled when starting the environment.

Name resolution
---------------

Set up unbound on your own machine, to facilitiate resolving docker-container
A from container B.

Linking is not the answer. When a named container restarts with a new IP the
'links' (aka. /etc/hosts entrys) in other containers are not updated.

    # apt-get install unbound
    # cat > /etc/unbound/unbound.conf.d/docker.conf << EOF
    server:
        domain-insecure: docker.
    forward-zone:
        name: docker.
        forward-addr: 172.17.0.1
    EOF
    # service unbound restart


Running
-------

Start all the containers with the start.sh file in this repository.

    # ./start.sh

The first time it will ask you for sudo rights to be able to write in your /etc/hosts.

etcd configuration
------------------

  The microservices and dashboard js uses etcd to get their configuration.

  To update the configuration edit etcd/conf.yaml and run `python etcd/etcd_config_bootstrap.py --host etcd.eduid.docker`.

Logging
-------

  To follow most logs you can use screen, run `screen -c screenrc`.

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
eduid-developer/eduid-signup/log/eduid-signup.log (the whole confirmation
e-mail will be logged instead of sent using SMTP).
