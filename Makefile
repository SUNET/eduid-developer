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
	(echo "Logs are in /var/log/eduid/"; docker run -it --init --rm --name showlogs -v eduidlogdata:/var/log/eduid docker.sunet.se/eduid/eduid-webapp bash)

show_appdata:
	(echo "Data is in /appdata/"; docker run -it --init --rm --name appdata -v appdata:/appdata docker.sunet.se/eduid/eduid-webapp bash)

mongodb_cli:
	./bin/docker-compose -f eduid/compose.yml exec mongodb mongo

vagrant_show_logs:
	(echo "Logs are in /var/log/eduid/"; vagrant ssh -c "cd /opt/eduid-developer; make show_logs")

vagrant_show_appdata:
	(echo "Data is in /appdata/"; vagrant ssh -c "cd /opt/eduid-developer; make show_appdata")

vagrant_mongodb:
	vagrant ssh -c "cd /opt/eduid-developer; make mongodb_cli"

vagrant_destroy:
	vagrant destroy

.PHONY: vagrant_run start vagrant_start vagrant_ssh stop vagrant_stop vagrant_halt up vagrant_up pull vagrant_pull update_etcd vagrant_update_etcd vagrant_destroy
