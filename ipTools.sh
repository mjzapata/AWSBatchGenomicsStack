#!/bin/bash

#getip
ARGUMENT=$1

function print_help(){
	echo "This script accepts one or two arguments."
	echo "This script is used to either return the users local IP address or
	update the ingress IP address of the stack's security group"
	echo "usage: ipTools.sh getip"
	echo "usage: ipTools.sh describesgingress STACKNAME"
	echo "usage: ipTools.sh updatesgingress STACKNAME"
	echo "usage: ipTools.sh updatesg STACKNAME 'description of location' "

}

function return_ip(){
	MYPUBLICIPADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//' )
	MASK=32
	MYPUBLICIPADDRESS=${MYPUBLICIPADDRESS}"/"${MASK}
	echo $MYPUBLICIPADDRESS
}

if [ $# -eq 1 ]; then
	MYPUBLICIPADDRESS=$(return_ip)
	if [ $ARGUMENT == "getip" ]; then
		echo $MYPUBLICIPADDRESS
	else
		print_help
	fi

elif [ $# -gt 1 ] && [ $# -lt 4 ]; then
	STACKNAME=$2
	AWSCONFIGFILENAME=~/.batchawsdeploy/${STACKNAME}.sh
	source $AWSCONFIGFILENAME

	MYPUBLICIPADDRESS=$(return_ip)

	if [ $ARGUMENT == "updatesgingress" ]; then
		DESCRIPTION=$3

		#TODO: rewrite MYPUBLICIPADDRESS in the source
		echo "MyIPAddress=$MYPUBLICIPADDRESS"
		echo "BASTIONSECURITYGROUP=$BASTIONSECURITYGROUP"

		#echo '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "'$MYPUBLICIPADDRESS'", "'$DESCRIPTIONWEB'"}]}]'
		now=$(date +'%m-%d-%Y')
		DESCRIPTION="$now $DESCRIPTION" #_$now
		echo "DESCRIPTION=$DESCRIPTION"

		aws ec2 authorize-security-group-ingress \
		--group-id $BASTIONSECURITYGROUP \
		--ip-permissions IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges='[{CidrIp='$MYPUBLICIPADDRESS',Description="'"$DESCRIPTION"'"}]'

		aws ec2 authorize-security-group-ingress \
		--group-id $BASTIONSECURITYGROUP \
		--ip-permissions IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges='[{CidrIp='$MYPUBLICIPADDRESS',Description="'"$DESCRIPTION"'"}]'

	elif [ $ARGUMENT == "describesgingress" ]; then
		sgRules=$(aws ec2 describe-security-groups --group-id $BASTIONSECURITYGROUP | grep -m1 $MYPUBLICIPADDRESS)
		if [ -z "$sgRules"  ]; then
			echo "No access to security group"
		else
			echo "Access to security group"
		fi

	else
		print_help
	fi

else
	print_help
fi

