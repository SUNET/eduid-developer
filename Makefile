start:
	./start.sh

vagrant_start:
	./start.sh --vagrant

stop:
	./stop.sh

vagrant_stop:
	vagrant halt

up:
	./bin/docker-compose -f eduid/compose.yml up -d

pull:
	./bin/docker-compose -f eduid/compose.yml pull

update_etcd:
	(cd etcd; python etcd_config_bootstrap.py --host etcd.eduid.docker)

.PHONY: start vagrant_start stop up pull update_etcd
