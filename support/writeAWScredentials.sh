#!/bin/bash

#PROFILE=batchcompute
#REGION=us-east-1
#OUTPUTFORMAT=text
#AWSACCESSKEYID=mysecretkeyid
#AWSSECRETACCESSKEY=mysecretkey
#writeAWScredentials.sh $PROFILE $REGION $OUTPUTFORMAT $AWSACCESSKEYID $AWSSECRETACCESSKEY

if [ $# -eq 5 ]; then
	PROFILE=$1
	REGION=$2
	OUTPUTFORMAT=$3
	AWSACCESSKEYID=$4
	AWSSECRETACCESSKEY=$5

	mkdir -p ~/.aws/
	
	#unlock the files
	chmod -R 777 ~/.aws/

	echo -e "[profile ${PROFILE}]\noutput = ${OUTPUTFORMAT}\nregion = ${REGION}" > ~/.aws/config
	echo -e "[${PROFILE}]\naws_access_key_id = ${AWSACCESSKEYID}\naws_secret_access_key = ${AWSSECRETACCESSKEY}" > ~/.aws/credentials

	#relock the files
	echo "relocking the files"
	chmod -R 600 ~/.aws/

else


	echo "Usage: writeAWScredentials.sh PROFILE REGION OUTPUTFORMAT AWSACCESSKEYID AWSSECRETACCESSKEY "
fi

