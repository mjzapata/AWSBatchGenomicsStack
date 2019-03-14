#!/bin/bash

#Purpose:  The purpose of this script is to create a keypair and also remove it after the creation of an AMI
print_error() {
	echo "$1"
	echo "Usage: 
	awskeypair create MyKeyName
	awskeypair delete MyKeyName
	awskeypair list MyKeyName
	awskeypair list"
}

ARGUMENT=$1

if [ $# -eq 2 ]; then
	KEYNAME=$2
	KEYPATH=~/.batchawsdeploy/key_${KEYNAME}.pem
	
	if [ "$ARGUMENT" == "create" ]; then
		# if a key by that name does not exist in the described key-pairs, create it.  Else, do nothing
		keydescription=$(aws ec2 describe-key-pairs)
		keystatus=$(echo "$keydescription" | grep -c "$KEYNAME")
		if [ ! -f $KEYPATH ]; then
			if [ $keystatus -eq 0 ]; then
				aws ec2 create-key-pair --key-name $KEYNAME --query 'KeyMaterial' --output text > $KEYPATH
				#this is a security requirement for keypairs to be used
				chmod 400 $KEYPATH
			else
				echo "keystatus=$keystatus"
				echo "warning: key with name: $KEYNAME  already exists!"
			fi
		else
			echo "keystatus=$keystatus"
			echo "warning: key with name: $KEYNAME  already exists!"
		fi

	elif [ "$ARGUMENT" == "delete" ]; then
		chmod 777 $KEYPATH
		echo "deleting Key File: $KEYPATH"
		rm $KEYPATH
		echo "deleting KeyPair: $KEYNAME"
		aws ec2 delete-key-pair --key-name $KEYNAME

	elif [ "$ARGUMENT" == "list" ]; then
		aws ec2 describe-key-pairs --key-name $KEYNAME

	else
		print_error "error: first argument must be: create, delete, or list"
	fi


elif [ $# -eq 1 ]; then
	if [ "$ARGUMENT" == "list" ]; then
		echo "list"
		aws ec2 describe-key-pairs
	else
		print_error 'error: more arguments required unless using: list'
	fi
else

	print_error 'error: requires one or two arguments'
fi

