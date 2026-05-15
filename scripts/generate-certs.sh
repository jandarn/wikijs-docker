#!/bin/bash

# this script is used to generate a ca and a certificate for nginx HTTPS, the ca files are deposited on certs/ca and the nginx certificate is deposited on nginx/ssl/

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

set +a
source "$PROJECT_ROOT/.env"
set -a

CERT_FILES_PATH="$PROJECT_ROOT/certs"
NGINX_SSL_PATH="$PROJECT_ROOT/nginx/ssl"

if [ ! -d "$CERT_FILES_PATH" ]; then
    mkdir -p "$CERT_FILES_PATH"

fi

if [ ! -d "$CERT_FILES_PATH/nginx" ]; then
    mkdir -p "$CERT_FILES_PATH/nginx"
fi

if [ ! -d "$NGINX_SSL_PATH" ]; then
    mkdir -p "$NGINX_SSL_PATH"
fi

# if there is no existing ca certificate or ca private key
if [ ! -f "$CERT_FILES_PATH/ca.crt" ] || [ ! -f "$CERT_FILES_PATH/ca.key" ]; then
    # generate ca private key
    openssl genrsa -out "$CERT_FILES_PATH/ca.key" 4096
    # generate ca certificate
    openssl req -x509 -new -nodes -key "$CERT_FILES_PATH/ca.key" -sha256 -days 3650 -out "$CERT_FILES_PATH/ca.crt" -subj "/C=ES/ST=Madrid/L=Madrid/O=WikiJS Docker CA by Onyxdream/OU=Infra/CN=$DOMAIN"
fi

# generate nginx private key
openssl genrsa -out "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.key" 4096

# generate nginx certificate signing request
openssl req -new -key "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.key" -out "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.csr" -subj "/C=ES/ST=Madrid/L=Madrid/O=$ORGANIZATION/OU=Infra/CN=$DOMAIN"

# generate SAN .ext file for subdomains
cat > "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.ext" <<EOL
subjectAltName = @alt_names
[alt_names]
DNS.1 = wiki.$DOMAIN
DNS.2 = grafana.$DOMAIN
EOL

# sign the nginx certificate with the ca certificate
openssl x509 -req -in "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.csr" -CA "$CERT_FILES_PATH/ca.crt" -CAkey "$CERT_FILES_PATH/ca.key" -CAcreateserial -out "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.crt" -days 398 -sha256 -extfile "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.ext"

# copy the nginx certificate and key to the nginx ssl directory with the name ssl.crt
cp "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.crt" "$NGINX_SSL_PATH/ssl.crt"
cp "$CERT_FILES_PATH/nginx/$SSL_CERT_NAME.key" "$NGINX_SSL_PATH/ssl.key"

echo "Certificate generated successfully. Please add the $CERT_FILES_PATH/ca.crt file to your trusted root certificate authorities. You can now access the wiki and grafana with HTTPS."