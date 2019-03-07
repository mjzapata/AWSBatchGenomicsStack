#!/bin/bash

#PROFILE=batchcompute
#REGION=us-east-1
#OUTPUTFORMAT=text
#AWSACCESSKEYID=mysecretkeyid
#AWSSECRETACCESSKEY=mysecretkey
#writeAWScredentials.sh $PROFILE $REGION $OUTPUTFORMAT $AWSACCESSKEYID $AWSSECRETACCESSKEY
ARGUMENT=$1

if [ $# -eq 1 ] && [ "$ARGUMENT" == "validate" ]; then
	testCredentials=$(aws iam get-user) 
	error=$?
	if [ $error != 0 ]; then
    	echo "AWS credentials error code: $error"
    	echo $testCredentials
    	exit 1
    else
    	echo "valid"
    fi

elif [ $# -eq 5 ] && [ "$ARGUMENT" == "write" ]; then
	PROFILE=$2
	REGION=$3
	OUTPUTFORMAT=$4
	AWSACCESSKEYID=$5
	AWSSECRETACCESSKEY=$6

	mkdir -p ~/.aws/
	
	#unlock the files
	chmod -R 777 ~/.aws/

	echo -e "[profile ${PROFILE}]\noutput = ${OUTPUTFORMAT}\nregion = ${REGION}" > ~/.aws/config
	echo -e "[${PROFILE}]\naws_access_key_id = ${AWSACCESSKEYID}\naws_secret_access_key = ${AWSSECRETACCESSKEY}" > ~/.aws/credentials

	#relock the files
	echo "relocking the files"
	chmod -R 600 ~/.aws/
else
	echo "Usage: configAWScredentials.sh PROFILE REGION OUTPUTFORMAT AWSACCESSKEYID AWSSECRETACCESSKEY "
fi

