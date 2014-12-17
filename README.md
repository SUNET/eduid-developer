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
    # ./build signup


Name resolving
--------------

Set up unbound on your own machine, to facilitiate resolving docker-container
A from container B.

Linking is not the answer. When a named container restarts with a new IP the
'links' (aka. /etc/hosts entrys) in other containers are not updated.

    # apt-get install unbound
    # cat > /etc/unbound/unbound.conf.d/docker.conf << EOF
    server:
        interface: 127.0.0.1
        interface: 172.17.42.1
        access-control: 172.17.0.0/16 allow
    EOF
    # service unbound reload


Starting
--------

Now, start some containers with the files in this repository.

    # (cd rabbitmq && ./run.sh) &
    # (cd mongodb && ./run.sh) &
    # (cd eduid-signup && ./run.sh) &

and then, update local-data in your unbound resolver with the IPs of your
newly started containers

    # ./update-dns
