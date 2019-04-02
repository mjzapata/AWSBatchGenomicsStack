#!/bin/bash

instanceID=$1
ARGUMENT=$2

# 1 ipaddress
# aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress"
# 2 ipaddresspublic
#aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].PublicIpAddress"
# 3 hostnamepublic
# aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].PublicDnsName"
# 4 hostname
# aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].PrivateDnsName"
# 5 status
# aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].State.Name"
# 6 reachability

# 7 sytstemstatus
#none

print_error(){
	echo "Usage: getinstance.sh instanceID value to query, such as ipaddress, hostname, status"
}

# if [ "$ARGUMENT" == "ipaddress" ]; then
# aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress"
# fi

if [ $# -gt 1 ]; then

	if [ "$ARGUMENT" == "systemstatus" ]; then

		instances=$(aws ec2 describe-instance-status --instance-ids $instanceID | grep "SYSTEMSTATUS")

		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[1]}"
			echo $var
		done | paste -s -d, /dev/stdin
	else
		aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].${ARGUMENT}"
	fi
else
	print_error
fi

