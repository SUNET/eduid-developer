#!/bin/sh

if [ ! -f eduid/compose.yml ]; then
    echo "Run $0 from the eduid-developer top level directory"
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        --vagrant )             vagrant=true
                                ;;
        -h | --help )           echo "usage: start.sh [--vagrant]"
                                exit
    esac
    shift
done

#
# Set up entrys in /etc/hosts for the containers with externally accessible services
# DON'T USE THE eduid_dev ONES, COOKIES ARE SCOPED FOR eduid.docker
#
(printf "172.16.10.200\tidp.eduid.docker\n";
    printf "172.16.10.210\tsignup.eduid.docker\n";
    printf "172.16.10.215\tamapi.eduid.docker\n";
    printf "172.16.10.220\tdashboard.eduid.docker\n";
    printf "172.16.10.223\tsupport.eduid.docker\n";
    printf "172.16.10.224\tpersonal-data.eduid.docker\n";
    printf "172.16.10.225\temail.eduid.docker\n";
    printf "172.16.10.226\tphone.eduid.docker\n";
    printf "172.16.10.227\tsecurity.eduid.docker\n";
    printf "172.16.10.228\tauthn.eduid.docker\n";
    printf "172.16.10.229\teidas.eduid.docker\n"
    printf "172.16.10.230\thtml.eduid.docker\n";
    printf "172.16.10.232\tbankid.eduid.docker\n";
    printf "172.16.10.235\tapi.eduid.docker\n";
    printf "172.16.10.236\tneo4jdb.eduid.docker\n";
    printf "172.16.10.240\tactions.eduid.docker\n";
    printf "172.16.10.242\tactions2.eduid.docker\n";
    printf "172.16.10.250\tturq.eduid.docker\n";
    printf "172.16.10.251\trabbitmq.eduid.docker\n";
    printf "172.16.10.252\tredis.eduid.docker\n";
    printf "172.16.10.253\tmongodb.eduid.docker\n";
) \
    | while read line; do
    if ! grep -q "^${line}$" /etc/hosts; then
	echo "$0: Adding line '${line}' to /etc/hosts"
	if [ "x`whoami`" = "xroot" ]; then
	    echo "${line}" >> /etc/hosts
	else
	    echo "${line}" | sudo tee -a /etc/hosts
	fi
    else
	echo "Line '${line}' already in /etc/hosts"
    fi
done

if [ "$vagrant" = true ]; then
    vagrant ssh -c "cd /opt/eduid-developer; make start"
else
    ./bin/docker-compose -f eduid/compose.yml rm -s -f
    ./bin/docker-compose -f eduid/compose.yml up $*
    ./bin/docker-compose -f eduid/compose.yml logs -tf
fi
