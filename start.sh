#!/bin/sh

if [ ! -f eduid/compose.yml ]; then
    echo "Run $0 from the eduid-developer top level directory"
    exit 1
fi

#
# Set up entrys in /etc/hosts for the containers with externally accessible services
#
(printf "172.16.10.200\tidp.eduid_dev idp.docker\n";
    printf "172.16.10.210\tsignup.eduid_dev signup.docker\n";
    printf "172.16.10.220\tdashboard.eduid_dev dashboard.docker\n";
    printf "172.16.10.230\thtml.eduid_dev html.docker\n";
    printf "172.16.10.252\tredis.eduid_dev redis.docker\n";
    printf "172.16.10.253\tmongodb.eduid_dev mongodb.docker\n";
    printf "172.16.10.254\tetcd.eduid_dev etcd.docker\n";
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

./bin/docker-compose -f eduid/compose.yml rm -f --all
./bin/docker-compose -f eduid/compose.yml up $*