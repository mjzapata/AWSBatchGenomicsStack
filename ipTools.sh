#!/bin/bash
ARGUMENT=$1

# reduce the last number to be more leniant about ip a ddresses, for example if a university has multiple IPs
#Get local public IPaddress https://askubuntu.com/questions/95910/command-for-determining-my-public-ip 
# curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'  
#MYPUBLICIPADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//' )
#MASK=32
#MYPUBLICIPADDRESS=${MYPUBLICIPADDRESS}"/"${MASK}

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
	BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
	source $BATCHAWSCONFIGFILE

	MYPUBLICIPADDRESS=$(return_ip)

	if [ $ARGUMENT == "updatesgingress" ]; then
		DESCRIPTION=$3

		#TODO: rewrite MYPUBLICIPADDRESS in the source
		echo "MyIPAddress=$MYPUBLICIPADDRESS"
		echo "BASTIONSECURITYGROUP=$BASTIONSECURITYGROUP"

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

