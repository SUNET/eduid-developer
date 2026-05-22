DOCKER=$(shell which docker)

start:
	./start.sh

stop:
	./stop.sh

up:
	$(DOCKER) compose -f eduid/compose.yml up -d --remove-orphans

pull:
	$(DOCKER) compose -f eduid/compose.yml pull

show_logs:
	docker run -it --init --rm --name showlogs --workdir /var/log/eduid/ -v eduidlogdata:/var/log/eduid -v mongodblogdata:/var/log/mongodb -v htmlnginxlogdata:/var/log/nginx/eduid-html busybox:stable sh

show_appdata:
	docker run -it --init --rm --name appdata --workdir /appdata -v appdata:/appdata busybox:stable sh

cp_appdata:
	(echo "You need 'show_appdata' running in another terminal"; docker cp appdata:/appdata/${file} .)

mongodb_cli:
	$(DOCKER) compose -f eduid/compose.yml exec mongodb mongosh

build_frontend_bundle:
	ls -l sources/eduid-front/build
	docker run --rm -it \
		-v ${CURDIR}/scripts/build-frontend-bundle.sh:/build-frontend-bundle.sh:ro \
		-v ${CURDIR}/sources/eduid-front:/src/eduid-front \
		docker.sunet.se/sunet/docker-jenkins-node-job /build-frontend-bundle.sh
	ls -l sources/eduid-front/build

build_managed_account_bundle:
	ls -l sources/eduid-managed-accounts/dist
	docker run --rm -it \
		-v ${CURDIR}/scripts/build-managed-accounts-bundle.sh:/build-managed-accounts-bundle.sh:ro \
		-v ${CURDIR}/sources/eduid-managed-accounts:/src/eduid-managed-accounts \
		docker.sunet.se/sunet/docker-jenkins-node-job /build-managed-accounts-bundle.sh
	ls -l sources/eduid-managed-accounts/dist

frontend_npm_start:
	docker run --rm -it \
		-v ${CURDIR}/scripts/frontend-npm-start.sh:/frontend-npm-start.sh:ro \
		-v ${CURDIR}/sources/eduid-front:/src/eduid-front \
		docker.sunet.se/sunet/docker-jenkins-node-job /frontend-npm-start.sh

developer_release:
	@echo "Version expected to be a timestamp: '$(VERSION)'"
	@echo $(VERSION) | grep -qE '^[0-9]{8}T[0-9]{6}$$'
	grep -E '[0-9]{8}T[0-9]{6}-staging$$' ./eduid/compose.yml | awk -F ':' '{print $$NF}' | sort | uniq | while read ver; do \
		sed -ie "s/$${ver}/$(VERSION)-staging/g" ./eduid/compose.yml ; \
	done
	git commit -m "Updated version to $(VERSION)" ./eduid/compose.yml

.PHONY: start stop up pull show_logs show_appdata cp_appdata mongodb_cli build_frontend_bundle frontend_npm_start
