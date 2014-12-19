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
    EOF
    # service unbound reload


Running
-------

Now, start some containers with the files in this repository. I would recommend
starting all these in a 'screen'.

    # (cd rabbitmq && ./run.sh) &
    # (cd mongodb && ./run.sh) &
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

Turq (a mock HTTP server) is used to fake 'OK' responses to all calls to the VCCS
authentication backend. The 'control-panel' for Turq is available at

  http://turq.docker:13085/+turq/


Services
--------

  http://signup.docker:8080/
  http://dashboard.docker:8080/

  http://turq.docker:13085/+turq/
  http://rabbitmq.docker:15672/   (login: admin/password)

