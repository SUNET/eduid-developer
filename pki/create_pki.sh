#! /bin/sh

set -e

service_names="dashboard eidas html idp signup support api"

# Generate CA key and cert
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

        openssl req -new -sha256 -nodes -out ${service_name}.csr -newkey rsa:2048 -keyout ${service_name}.key -config ${service_name}.conf
        openssl x509 -req -in ${service_name}.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out ${service_name}.crt -days 730 -sha256 -extfile ${service_name}.ext
        cat ${service_name}.key ${service_name}.crt rootCA.crt > ${service_name}.pem
fi
}


for service_name in ${service_names}; do
        create_leaf_cert ${service_name}
done