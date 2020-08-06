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


Create a file name __vagrant.yml__ in the repository root containing the following yaml:

    local_paths:
      eduid_front: '/path/to/eduid-front'
      eduid_html: '/path/to/eduid-html'
    vm:
      cpus: 2
      memory: 4096
      disksize: '20GB'

Then run:

    $ make vagrant_run  (only needed once per session)
    $ make vagrant_start

To connect to the vagrant vm:

    $ make vagrant_ssh


Stopping
--------

##### Linux Docker environment

    $ make stop


##### Other OS Vagrant environment

    $ make vagrant_stop
    $ make vagrant_halt


etcd configuration
------------------

  The microservices and dashboard js uses etcd to get their configuration.

  To update the configuration edit etcd/conf.yaml and run `make update_etcd`.

TLS certificate
---------------

  #####  Linux Docker environment

  Run `create_pki.sh` in the `pki` directory before starting your environment.

  ##### Other OS Vagrant environment

  The script for creating the certificates will be run on `make vagrant_run`.

  ##### All OS

  The root certificate authority (CA) certificate is located at `pki/rootCA.crt`. This should be added to your browsers certificate in the Authorities section or equivalent.

  This certificate is generated for each environment so it should be ok to add it to your browser, but keep in mind that you should keep the rootCA.key to yourself as it can be used to do targeted man-in-the-middle attacks against your development machine.

Logging
-------

All logs from webapps are kept in a shared data volume called eduidlogdata.

For a quick tail -F run, ex:

    $ ./bin/tailf signup

To get a shell with mounted log files:

##### Linux Docker environment

    $ make show_logs

##### Other OS Vagrant environment

    $ make vagrant_show_logs

Authentication
--------------

Turq (a mock HTTP server) is used to fake 'OK' responses to all calls to the
VCCS authentication backend.

Services
--------

  https://signup.eduid.docker/
  https://dashboard.eduid.docker/
  https://html.eduid.docker/
  https://support.eduid.docker/

  http://turq.eduid.docker:13085/+turq/

  mongodb://mongodb.eduid.docker
  redis://redis.eduid.docker
  etcd://etcd.eduid.docker
  neo4j://neo4jdb.eduid.docker

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

The confirmation email will be available in the log file.


ORCID
-----

You need to obtain the OIDC secrets for the ORCID sandbox from a colleague.
Create a file named __oidc_client_creds.yaml__ in `eduid-orcid/etc/` that looks like below.

```yaml
---
CLIENT_REGISTRATION_INFO:
  client_id: the_client_id
  client_secret: the_client_secret
```

Local Docker vs Vagrant
-----------------------

If you want to run both you need to reset your networking before switching.

##### Docker:

    $ docker network rm eduid_dev

##### Vagrant (Virtualbox):

Open Virtualbox and go to File -> Host Network Manager and remove the network 172.16.10.0/24.

Makefile recipes
-----------------
Recipes that starts with "vagrant\_" should be run from the host OS when using vagrant.

    $ make vagrant_run          # Start vagrant vm
    $ make start                # Starts all containers using docker-compose
    $ make vagrant_start        # See above
    $ make vagrant_ssh          # Starts a shell in the vagrant vm
    $ make stop                 # Stops all containers using docker-compose
    $ make vagrant_stop         # See above
    $ make vagrant_halt         # Stops all containers and shuts the vagrant vm down
    $ make up                   # Tries to start all non-running containers
    $ make vagrant_up           # See above
    $ make update_etcd          # Runs the configuration import script for etcd
    $ make vagrant_update_etcd  # See above
    $ make pull                 # Pull all images using docker-compose
    $ vagrant_pull              # See above
    $ make show_logs            # Starts a shell in a container with the log data volume mounted
                                # Log files can be found in /var/log/eduid
    $ make vagrant_show_logs    # See above
    $ make vagrant_destroy      # Halts and removes the vagrant vm

