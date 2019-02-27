#!/bin/bash

#getip
ARGUMENT=$1

function print_help(){
	echo "This script accepts one or two arguments."
	echo "This script is used to either return the users local IP address or
	update the ingress IP address of the stack's security group"
	echo "usage: ./ipTools.sh getip"
	echo "usage: ./ipTools.sh updatesg STACKNAME"
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

elif [ $# -eq 2 ]; then

	if [ $ARGUMENT == "updatesg" ]; then
		STACKNAME=$2
		source ~/.profile
		AWSCONFIGFILENAME=${BATCHAWSDEPLOY_HOME}${STACKNAME}.sh
		source $AWSCONFIGFILENAME

		#MYPUBLICIPADDRESS=$(return_ip)
		#MYPUBLICIPADDRESS="2.2.2.8/32"

		#TODO: rewrite MYPUBLICIPADDRESS in the source
		echo "MyIPAddress: $MYPUBLICIPADDRESS"
		echo "BASTIONSECURITYGROUP=$BASTIONSECURITYGROUP"
		DESCRIPTIONSSH="ingress from last known IP ssh"
		DESCRIPTIONWEB="ingress from last known IP web"
		DESCRIPTIONSSL="ingress from last known IP ssl"

		#echo '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "'$MYPUBLICIPADDRESS'", "'$DESCRIPTIONWEB'"}]}]'
		
		#aws ec2 authorize-security-group-ingress --group-id $BASTIONSECURITYGROUP --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=2.2.2.2/32,Description="RDP access from MY office"}]'
		#update security group ingress rules
		aws ec2 authorize-security-group-ingress \
		--group-id $BASTIONSECURITYGROUP \
		--ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp='$MYPUBLICIPADDRESS',Description="'"$DESCRIPTIONSSH"'"}]'

		aws ec2 authorize-security-group-ingress \
		--group-id $BASTIONSECURITYGROUP \
		--ip-permissions IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges='[{CidrIp='$MYPUBLICIPADDRESS',Description="'"$DESCRIPTIONWEB"'"}]'

		aws ec2 authorize-security-group-ingress \
		--group-id $BASTIONSECURITYGROUP \
		--ip-permissions IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges='[{CidrIp='$MYPUBLICIPADDRESS',Description="'"$DESCRIPTIONSSL"'"}]'

	else
		print_help
	fi

else
	print_help
fi

