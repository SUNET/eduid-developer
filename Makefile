vagrant_run:
	vagrant up

start:
	./start.sh

vagrant_start:
	./start.sh --vagrant

vagrant_ssh:
	vagrant ssh

stop:
	./stop.sh

vagrant_stop:
	vagrant ssh -c "cd /opt/eduid-developer; make stop"

vagrant_halt: vagrant_stop
	vagrant halt

up:
	./bin/docker-compose -f eduid/compose.yml up -d

vagrant_up:
	vagrant ssh -c "cd /opt/eduid-developer; make up"

vagrant_docker_ps:
	vagrant ssh -c "docker ps"

pull:
	./bin/docker-compose -f eduid/compose.yml pull

vagrant_pull:
	vagrant ssh -c "cd /opt/eduid-developer; make pull"

update_etcd:
	(cd etcd; python etcd_config_bootstrap.py --host etcd.eduid.docker)

vagrant_update_etcd:
	vagrant ssh -c "cd /opt/eduid-developer; make update_etcd"

show_logs:
	docker run -it --init --rm --name showlogs --workdir /var/log/eduid/ -v eduidlogdata:/var/log/eduid docker.sunet.se/eduid/eduid-webapp bash

show_appdata:
	docker run -it --init --rm --name appdata --workdir /appdata -v appdata:/appdata docker.sunet.se/eduid/eduid-webapp bash

cp_appdata:
	(echo "You need 'show_appdata' running in another terminal"; docker cp appdata:/appdata/${file} .)

mongodb_cli:
	./bin/docker-compose -f eduid/compose.yml exec mongodb mongo

vagrant_show_logs:
	(vagrant ssh -c "cd /opt/eduid-developer; make show_logs")

vagrant_show_appdata:
	(vagrant ssh -c "cd /opt/eduid-developer; make show_appdata")

vagrant_cp_appdata:
	(vagrant ssh -c "cd /opt/eduid-developer; make cp_appdata file=${file}")

vagrant_mongodb_cli:
	vagrant ssh -c "cd /opt/eduid-developer; make mongodb_cli"

vagrant_destroy:
	vagrant destroy

.PHONY: vagrant_run start vagrant_start vagrant_ssh stop vagrant_stop vagrant_halt up vagrant_up pull vagrant_pull update_etcd vagrant_update_etcd show_logs vagrant_show_logs show_appdata vagrant_show_appdata cp_appdata vagrant_cp_appdata mongodb_cli vagrant_mongodb_cli vagrant_destroy
