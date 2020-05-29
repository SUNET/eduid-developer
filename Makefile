start:
	./start.sh

vagrant_start:
	vagrant up

stop:
	./stop.sh

up:
	./bin/docker-compose -f eduid/compose.yml up -d

pull:
	./bin/docker-compose -f eduid/compose.yml pull

update_etcd:
	(cd etcd; python etcd_config_bootstrap.py --host etcd.eduid.docker)

.PHONY: start stop up update_etcd
