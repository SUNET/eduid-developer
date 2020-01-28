#!/bin/sh

if [ ! -f eduid/compose.yml ]; then
    echo "Run $0 from the eduid-developer top level directory"
    exit 1
fi

#
# Set up entrys in /etc/hosts for the containers with externally accessible services
# DON'T USE THE eduid_dev ONES, COOKIES ARE SCOPED FOR eduid.docker
#
(printf "172.16.10.200\tidp.eduid_dev idp.eduid.docker\n";
    printf "172.16.10.210\tsignup.eduid_dev signup.eduid.docker\n";
    printf "172.16.10.211\tsignup2.eduid_dev signup2.eduid.docker\n";
    printf "172.16.10.212\tlogin.eduid_dev login.eduid.docker\n";
    printf "172.16.10.220\tdashboard.eduid_dev dashboard.eduid.docker\n";
    printf "172.16.10.223\tsupport.eduid_dev support.eduid.docker\n";
    printf "172.16.10.224\tpersonal-data.eduid_dev personal-data.eduid.docker\n";
    printf "172.16.10.225\temail.eduid_dev email.eduid.docker\n";
    printf "172.16.10.226\tphone.eduid_dev phone.eduid.docker\n";
    printf "172.16.10.227\tsecurity.eduid_dev security.eduid.docker\n";
    printf "172.16.10.228\tauthn.eduid_dev authn.eduid.docker\n";
    printf "172.16.10.229\teidas.eduid.docker\n"
    printf "172.16.10.230\thtml.eduid_dev html.eduid.docker\n";
    printf "172.16.10.240\tactions.eduid_dev actions.eduid.docker\n";
    printf "172.16.10.242\tactions2.eduid_dev actions2.eduid.docker\n";
    printf "172.16.10.243\torcid.eduid_dev orcid.eduid.docker\n";
    printf "172.16.10.250\tturq.eduid_dev turq.eduid.docker\n";
    printf "172.16.10.251\trabbitmq.eduid_dev rabbitmq.eduid.docker\n";
    printf "172.16.10.252\tredis.eduid_dev redis.eduid.docker\n";
    printf "172.16.10.253\tmongodb.eduid_dev mongodb.eduid.docker\n";
    printf "172.16.10.254\tetcd.eduid_dev etcd.eduid.docker\n";
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

./bin/docker-compose -f eduid/compose.yml rm -s -f
./bin/docker-compose -f eduid/compose.yml up $*
./bin/docker-compose -f eduid/compose.yml logs -tf
