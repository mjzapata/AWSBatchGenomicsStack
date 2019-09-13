#!/bin/bash

function print_help {
	"Usage: ./certication_tools.sh <ARGUMENT>"
	"Usage: ./certication_tools.sh self-signed"
	"Usage: ./certication_tools.sh self-signed <environment_file_path>"
}

argument=$1
if [ ! -z $2 ]; then
	environment_file_path=$2
else
	environment_file_path=.env
fi
source $environment_file_path

# make sure last character is a slash
if [[ "${CERT_DIRECTORY:${#CERT_DIRECTORY}-1}" == "/" ]]; then
	CERT_DIRECTORY="${CERT_DIRECTORY}"
else
	CERT_DIRECTORY="${CERT_DIRECTORY}/"
fi

mkdir -p ${CERT_DIRECTORY}

#echo "CERT_DIRECTORY=$CERT_DIRECTORY"

if [ "$COMMONNAME" == "AWSDEFINED" ]; then	
	publichostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
	COMMONNAME="$publichostname"
fi

# if no cert exists here, run this
# if no argument to force certificate regeneration

if [ "$argument" == "self-signed" ]; then
	openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    	-subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/CN=www.${COMMONNAME}" \
    	-keyout ${CERT_DIRECTORY}${COMMONNAME}.${key_suffix}  -out ${CERT_DIRECTORY}${COMMONNAME}.${cert_suffix}
fi

#openssl
#sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout data/certs/myec2webapp_selfsigned.key -out data/certs/myec2webapp_selfsigned.crt


