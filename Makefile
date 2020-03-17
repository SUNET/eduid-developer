start:
	./start.sh

stop:
	./stop.sh

up:
	./bin/docker-compose -f eduid/compose.yml up -d

update_etcd:
	(cd etcd; python etcd_config_bootstrap.py --host etcd.eduid.docker)

.PHONY: start stop up update_etcd
