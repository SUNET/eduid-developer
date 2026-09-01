#! /bin/sh

set -e

service_names="bankid dashboard eidas html idp idpproxy samleid signup support api developer managed-accounts"

# Generate CA key and cert
cat > ca.conf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn

[dn]
C  = SE
ST = Milky Way
L  = Earth
O  = Sunet
OU = eduID Dev
CN = eduid_dev_ca
EOF
if [ ! -f ./rootCA.key ]; then
    echo Creating Root CA

    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -config ca.conf
fi

# Create leaf certificates for each service
create_leaf_cert() {
        service_name=${1}

if [ ! -f ./${service_name}.key ]; then
    echo Creating leaf certificate for ${service_name}

    # Generate config files for openssl
    if [ ! -f ${service_name}.conf ]; then
	cat > ${service_name}.conf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn

[dn]
C  = SE
ST = Milky Way
L  = Earth
O  = Sunet
OU = eduid_dev_rootCA
CN = ${service_name}.eduid.docker
EOF
	conf_generated=1
    fi

    if [ ! -f ${service_name}.ext ]; then
	cat > ${service_name}.ext <<EOF
# v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${service_name}.eduid.docker
EOF
	ext_generated=1
    fi

    openssl req -new -sha256 -nodes -out ${service_name}.csr -newkey rsa:2048 -keyout ${service_name}.key -config ${service_name}.conf
    openssl x509 -req -in ${service_name}.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out ${service_name}.crt -days 730 -sha256 -extfile ${service_name}.ext
    cat ${service_name}.key ${service_name}.crt rootCA.crt > ${service_name}.pem

    # remove any generated config files
    if [ $conf_generated -eq 1 ]; then
	rm ${service_name}.conf
    fi
    if [ $ext_generated -eq 1 ]; then
	rm ${service_name}.ext
    fi
fi
}


for service_name in ${service_names}; do
        create_leaf_cert ${service_name}
done
