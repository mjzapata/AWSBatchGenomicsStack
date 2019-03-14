#!/bin/bash

#ARGUMENT=write
#PROFILE=batchcompute
#REGION=us-east-1
#OUTPUTFORMAT=text
#AWSACCESSKEYID=mysecretkeyid
#AWSSECRETACCESSKEY=mysecretkey
#writeAWScredentials.sh write $PROFILE $REGION $OUTPUTFORMAT $AWSACCESSKEYID $AWSSECRETACCESSKEY
source ~/.batchawsdeploy/config
ARGUMENT=$1
if [ $# -eq 1 ] && [ "$ARGUMENT" == "validate" ]; then
	testCredentials=$(aws iam get-user) 
	errorcode=$?
	if [ $errorcode != 0 ]; then
    	echo "AWS credentials error code: $errorcode"
    	echo $testCredentials
    	exit 1
    else
    	echo "valid"
    fi

elif [ $# -eq 1 ] && [ "$ARGUMENT" == "version" ]; then
	# CHECK AWS VERSION
	#https://stackoverflow.com/questions/19915452/in-shell-split-a-portion-of-a-string-with-dot-as-delimiter
	#https://stackoverflow.com/questions/2342826/how-to-pipe-stderr-and-not-stdout
	#example:
	#aws-cli/1.16.25  Python/2.7.15rc1 Linux/4.9.125-linuxkit botocore/1.12.15 (OUTDATED)
	#aws-cli/1.16.114 Python/2.7.16rc1 Linux/4.9.125-linuxkit botocore/1.12.104
	versions=$(aws --version 2>&1 >/dev/null) # | grep -o '[^-]*$')
	echo "versions=$versions"
	awsversion=$(echo $versions | cut -d ' ' -f1 | cut -d '/' -f2)
	echo "current aws-cli version:  $awsversion"
	awsmajor=$(echo $awsversion | cut -d. -f1); awsmajor_required=1
	awsminor=$(echo $awsversion | cut -d. -f2); awsminor_required=16
	awsmicro=$(echo $awsversion | cut -d. -f3); awsmicro_required=65

	if [ $(expr $awsmajor) -lt $awsmajor_required ] || \
	    [ $(expr $awsminor) -lt $awsminor_required ] || \
	    [ $(expr $awsmicro) -lt $awsmicro_required ]; then
	    echo -n "minimum required version: "
	    echo "${awsmajor_required}.${awsminor_required}.${awsmicro_required}"
	    echo "aws command line tool outdated. please update."
	    echo "type \"aws --version\" for more information"
	    exit 1
	fi


elif [ $# -eq 6 ] && [ "$ARGUMENT" == "write" ]; then
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
	#verbose
		#echo "relocking the files"
	chmod -R 600 ~/.aws/

	configAWScredentials.sh validate
else
	echo "
	Usage: configAWScredentials.sh validate
	Usage: configAWScredentials.sh write PROFILE REGION OUTPUTFORMAT AWSACCESSKEYID AWSSECRETACCESSKEY"
fi

