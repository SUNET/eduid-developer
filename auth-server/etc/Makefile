
saml-cert:
	openssl req -x509 -sha256 -days 3650 -nodes -newkey RSA:4096 -subj "/C=SE/CN=auth-dev-$(shell date +"%Y%m%d").eduid.docker" -keyout - -out saml.pem

