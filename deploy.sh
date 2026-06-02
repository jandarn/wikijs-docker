#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# check if the .env file exists, if not create it from the .env.example file, then prompt the user to run this script again
if [ ! -f $PROJECT_ROOT/.env ]; then
    if [ -f $PROJECT_ROOT/.env.example ]; then
        cp $PROJECT_ROOT/.env.example $PROJECT_ROOT/.env
        echo "Error: .env file not found. A new .env file has been created from the .env.example file. Please review the .env file and make sure it has the correct environment variables, then run this script again."
        exit 1
    else
        echo "Error: .env file not found and .env.example file not found. Please create a .env file with the necessary environment variables and try again."
        exit 1
    fi
fi

set -a
source $PROJECT_ROOT/.env
set +a


# if os is not linux, exit
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script is only supported on Linux. Please run it on a Linux machine."
    exit 1
fi

# check if the system has docker and docker-compose installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# check if the current user is on the docker group
if ! groups $USER | grep 'docker' &> /dev/null; then
    echo "Error: User $USER is not in the docker group. Please add the user to the docker group and try again."
    exit 1
fi

# check files
# docker-compose.yml

if [ ! -f $PROJECT_ROOT/docker-compose.yml ]; then
    echo "Error: docker-compose.yml file not found. Please create a docker-compose.yml file and try again."
    exit 1
fi

# /scripts
if [ ! -d $PROJECT_ROOT/scripts ]; then
    echo "Error: scripts directory not found. Please create a scripts directory and try again."
    exit 1
fi

# /scripts/generate-certs.sh
if [ ! -f $PROJECT_ROOT/scripts/generate-certs.sh ]; then
    echo "Error: generate-certs.sh script not found. Please create a generate-certs.sh script and try again."
    exit 1
fi


# check if the .env.example file is equal to the .env file
if [ -f $PROJECT_ROOT/.env.example ]; then
    if  diff -q $PROJECT_ROOT/.env.example $PROJECT_ROOT/.env &> /dev/null; then
        echo "The .env file is equal to the .env.example file. Please review the .env file and make sure it has the correct environment variables, then run this script again."
        exit 1
    fi
else
    echo "Error: .env.example file not found. Please create a .env.example file and try again."
    exit 1
fi

# check if the user has a valid certificate for nginx HTTPS
# First check if the .pem or .crt file exist
SSL_CERT_FILE="$PROJECT_ROOT/nginx/ssl/ssl"

if [ -f "$SSL_CERT_FILE.pem" ]; then
    echo "SSL certificate found: $SSL_CERT_FILE.pem"
    SSL_CERT_FILE="$SSL_CERT_FILE.pem"
elif [ -f "$SSL_CERT_FILE.crt" ]; then
    echo "SSL certificate found: $SSL_CERT_FILE.crt"
    SSL_CERT_FILE="$SSL_CERT_FILE.crt"
else
    echo "No SSL certificate found. Generating self-signed certificate..."
    bash $PROJECT_ROOT/scripts/generate-certs.sh
    SSL_CERT_FILE="$SSL_CERT_FILE.crt"
fi

# check if the domain of the certificate matches the domain in the .env file, if not, generate a new certificate with the correct domain information
CERT_INFO=$(openssl x509 -in "$SSL_CERT_FILE" -noout -text)

if ! echo "$CERT_INFO" | grep "wiki.$DOMAIN" &> /dev/null; then
    echo "The domain of the SSL certificate does not match the domain in the .env file. Generating a new certificate with the correct domain information..."
    bash $PROJECT_ROOT/scripts/generate-certs.sh
else
    echo "Domain Certificate: $DOMAIN - OK"
fi

# copy the nginx templates to the nginx conf.d directory with the correct domain information
if [ -f "$PROJECT_ROOT/scripts/nginx-conf.sh" ]; then
    bash $PROJECT_ROOT/scripts/nginx-conf.sh
else
    echo "Error: nginx-conf.sh script not found. Please clone again the repository and make sure the file exists."
    exit 1  
fi

if [ "$1" == "down" ]; then
    echo "Stopping Docker Compose services..."
    docker compose --profile ldap --profile localdb down
    echo "Docker Compose services stopped successfully."
    exit 0
fi

# check if docker compose is down, if not, restart
DOCKER_OUTPUT=$(docker compose ps | sed '1d')
PROFILES=""

if [ "$LDAP_TEST" == "true" ]; then
    PROFILES+=" --profile ldap"
    bash $PROJECT_ROOT/scripts/ldap-conf.sh
fi

if [ "$LOCAL_DB" == "true" ]; then
    PROFILES+=" --profile localdb"
fi

DOCKER_COMMAND="docker compose $PROFILES"

if [ -n "$DOCKER_OUTPUT" ]; then
    echo "Docker Compose is already running. Restarting the services..."
    sleep 1
    eval "$DOCKER_COMMAND down"
    sleep 1
    eval "$DOCKER_COMMAND up -d"
else
    echo "Starting Docker Compose services..."
    eval "$DOCKER_COMMAND up -d"
fi

echo -e '\n\033[1;32m_ _ _ _ _  _ _  _ ____    ___  ____ ____ _  _ ____ ____ \033[0m'
echo -e '\033[1;32m| | | | |_/  |  | [__  __ |  \ |  | |    |_/  |___ |__/ \033[0m'
echo -e '\033[1;32m|_|_| | | \_ | _| ___]    |__/ |__| |___ | \_ |___ |  \ \033[0m'
echo "--------------------------------------------------"
echo -e '\033[1;35m> https://github.com/jandarn/wikijs-docker\033[0m'
echo -e '\n\033[1;32m[+] Deployment completed successfully.\033[0m'
echo "- To undeploy, run 'deploy.sh down'."
echo "--------------------------------------"
echo -e '\033[1;33m[+] http://wiki.'"$DOMAIN"' - Wiki.js\033[0m'
echo -e '\033[1;33m[+] http://grafana.'"$DOMAIN"' - Grafana\033[0m'
if [ "$LDAP_TEST" == "true" ]; then
    echo -e '\033[1;33m[+] http://localhost:8081 - PhpLdapAdmin\033[0m'
fi
echo "--------------------------------------"
echo "Check README.md for more information about the deployment and configuration of the services."
