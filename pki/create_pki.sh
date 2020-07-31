#! /bin/sh

set -e

# Generate CA key and cert
if [ ! -f ./rootCA.key ]; then
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -config ca.conf
fi

# Generate service certs
## dashboard
if [ ! -f ./dashboard.key ]; then
    openssl req -new -sha256 -nodes -out dashboard.csr -newkey rsa:2048 -keyout dashboard.key -config dashboard.conf
    openssl x509 -req -in dashboard.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out dashboard.crt -days 3650 -sha256 -extfile dashboard.ext
    cat dashboard.key dashboard.crt rootCA.crt > dashboard.pem
fi

## eidas
if [ ! -f ./eidas.key ]; then
    openssl req -new -sha256 -nodes -out eidas.csr -newkey rsa:2048 -keyout eidas.key -config eidas.conf
    openssl x509 -req -in eidas.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out eidas.crt -days 3650 -sha256 -extfile eidas.ext
    cat eidas.key eidas.crt rootCA.crt > eidas.pem
fi

## html
if [ ! -f ./html.key ]; then
    openssl req -new -sha256 -nodes -out html.csr -newkey rsa:2048 -keyout html.key -config html.conf
    openssl x509 -req -in html.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out html.crt -days 3650 -sha256 -extfile html.ext
    cat html.key html.crt rootCA.crt > html.pem
fi

## idp
if [ ! -f ./idp.key ]; then
    openssl req -new -sha256 -nodes -out idp.csr -newkey rsa:2048 -keyout idp.key -config idp.conf
    openssl x509 -req -in idp.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out idp.crt -days 3650 -sha256 -extfile idp.ext
    cat idp.key idp.crt rootCA.crt > idp.pem
fi

## signup
if [ ! -f ./signup.key ]; then
    openssl req -new -sha256 -nodes -out signup.csr -newkey rsa:2048 -keyout signup.key -config signup.conf
    openssl x509 -req -in signup.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out signup.crt -days 3650 -sha256 -extfile signup.ext
    cat signup.key signup.crt rootCA.crt > signup.pem
fi
