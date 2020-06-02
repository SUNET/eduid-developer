start:
	./start.sh

vagrant_up:
	vagrant up

vagrant_start:
	./start.sh --vagrant

vagrant_ssh:
	vagrant ssh

stop:
	./stop.sh

vagrant_stop:
	(vagrant ssh -c "cd /opt/eduid-developer; make stop"; vagrant halt)

up:
	./bin/docker-compose -f eduid/compose.yml up -d

pull:
	./bin/docker-compose -f eduid/compose.yml pull

update_etcd:
	(cd etcd; python etcd_config_bootstrap.py --host etcd.eduid.docker)

show_logs:
	(echo "Logs are in /var/log/eduid/"; docker run -it --init --rm -v eduidlogdata:/var/log/eduid docker.sunet.se/eduid/eduid-webapp bash)

.PHONY: start vagrant_start stop up pull update_etcd
