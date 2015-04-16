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
    # ./build eduid-am
    # ./build eduid-msg
    # ./build eduid-dashboard
    # ./build eduid-signup
    # ./build eduid-idp


Name resolution
---------------

Set up unbound on your own machine, to facilitiate resolving docker-container
A from container B.

Linking is not the answer. When a named container restarts with a new IP the
'links' (aka. /etc/hosts entrys) in other containers are not updated.

    # apt-get install unbound
    # cat > /etc/unbound/unbound.conf.d/docker.conf << EOF
    server:
        local-zone: docker. static
        interface: 127.0.0.1
        interface: 172.17.42.1
        access-control: 172.17.0.0/16 allow
        local-data: "pypi.docker A 172.17.42.1"
    EOF
    # service unbound reload


Running
-------

Now, start some containers with the files in this repository. I would recommend
starting all these in a 'screen'.

    # (cd rabbitmq && ./run.sh) &
    # (cd mongodb && ./run.sh) &
    # ./update-dns
    # (cd eduid-am && ./run.sh) &
    # (cd eduid_msg && ./run.sh) &
    # (cd eduid-signup && ./run.sh) &
    # (cd eduid-dashboard && ./run.sh) &
    # (cd eduid-idp && ./run.sh) &
    # (cd turq && ./run.sh) &

and then, update local-data in your unbound resolver with the IPs of your
newly started containers

    # ./update-dns


Authentication
--------------

Turq (a mock HTTP server) is used to fake 'OK' responses to all calls to the
VCCS authentication backend. The 'control-panel' for Turq is available at

  http://turq.docker:13085/+turq/


Services
--------

  http://signup.docker:8080/
  http://dashboard.docker:8080/

  http://turq.docker:13085/+turq/
  http://rabbitmq.docker:15672/   (login: admin/password)

Local PyPI server
-----------------

If packages needs to be tested locally then change setup.py to reflect
the new version that is to be used, change setup.sh to point to
pypi.docker instead of e.g. pypi.nordu.net and install pypiserver.

    # pip install pypiserver passlib
    # apt-get install apache2-utils
    # mkdir -p ~/workspace/pypi/packages

Create at least one user to use when uploading packages.

    # htpasswd -sc .htaccess

Run pypiserver as a background job on port 8080 that redirects
to your main PyPI server if a package could not be found locally.

    # pypi-server --fallback-url https://pypi.nordu.net/simple -p 8080 -P .htaccess packages &

Create a ~./pypirc file containing at least:

    [distutils]
    index-servers = internal

    [internal]
    repository: http://localhost:8080
    username: <your pypiserver user>
    password: <your pypiserver password>

To upload a package, go to the directory containing the project that
you would like to upload and issue:

    # python setup.py sdist upload -r internal

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
