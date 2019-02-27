#!/bin/bash

#Purpose:  The purpose of this script is to create a keypair and also remove it after the creation of an AMI

#Usage:
# "Usage: awskeypair create MyKeyName,  awskeypair remove MyKeyName, awskeypair list MyKeyName,  awskeypair list"
ARGUMENT=$1

if [ $# -eq 3 ]; then
	KEYNAME=$2

	if [ "$ARGUMENT" == "create" ] && [ ! -f ~/.batchawsdeploy/${KEYNAME}.pem ]; then
	#if [ "$ARGUMENT" == "create" ]; then
		#TODO: what if the output file is empty
		# if a key by that name does not exist in the described key-pairs, create it.  Otherwise, do nothing
		keydescription=$(aws ec2 describe-key-pairs)
		keystatus=$(echo "$keydescription" | grep -c "$KEYNAME")
		if [ $keystatus -eq 0 ]; then
			aws ec2 create-key-pair --key-name $KEYNAME --query 'KeyMaterial' --output text > ${BATCHAWSDEPLOY_HOME}${KEYNAME}.pem
			#this is a security requirement for keypairs to be used
			chmod 400 ${BATCHAWSDEPLOY_HOME}${KEYNAME}.pem
		else
			echo "key with name: $KEYNAME  already exists!"
		fi


	elif [ "$ARGUMENT" == "list" ]; then
		aws ec2 describe-key-pairs --key-name $KEYNAME

	elif [ "$ARGUMENT" == "delete" ]; then
		echo "deleting $KEYNAME"
		chmod 777 ${BATCHAWSDEPLOY_HOME}${KEYNAME}.pem
		rm ${BATCHAWSDEPLOY_HOME}${KEYNAME}.pem
		aws ec2 delete-key-pair --key-name $KEYNAME

	else
		echo "Usage: awskeypair create MyKeyName,  awskeypair remove MyKeyName, awskeypair list MyKeyName,  awskeypair list"
	fi


elif [ $# -eq 1 ]; then
	if [ "$ARGUMENT" == "list" ]; then
		echo "list"
		aws ec2 describe-key-pairs
	else
		echo "Usage: awskeypair create MyKeyName,  awskeypair remove MyKeyName, awskeypair list MyKeyName,  awskeypair list"
	fi
else

	echo "Usage: awskeypair create MyKeyName,  awskeypair remove MyKeyName, awskeypair list MyKeyName,  awskeypair list"

fi

