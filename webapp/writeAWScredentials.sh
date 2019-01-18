#!/bin/bash


#PROFILE=default
#REGION=us-east-1
#OUTPUTFORMAT=text
#AWSACCESSKEYID=mysecretkeyid
#AWSSECRETACCESSKEY=mysecretkey

git clone https://github.com/mjzapata/BLJBatchAWS.git

if [ $# -eq 5 ]; then
	PROFILE=$1
	REGION=$2
	OUTPUTFORMAT=$3
	AWSACCESSKEYID=$4
	AWSSECRETACCESSKEY=$5

	mkdir -p ~/.aws
	echo -e "[${PROFILE}]\noutput = ${OUTPUTFORMAT}\nregion = ${REGION}" > ~/.aws/config
	echo -e "[${PROFILE}]\naws_access_key_id = ${AWSACCESSKEYID}\naws_secret_access_key = ${AWSSECRETACCESSKEY}" > ~/.aws/credentials

	chmod 600 ~/.aws/config
	chmod 600 ~/.aws/credentials

else


	echo "Usage: ./writeAWScredentials.sh PROFILE REGION OUTPUTFORMAT AWSACCESSKEYID AWSSECRETACCESSKEY"
fi


./writeAWScredentials.sh $PROFILE $REGION $OUTPUTFORMAT $AWSACCESSKEYID $AWSSECRETACCESSKEY
