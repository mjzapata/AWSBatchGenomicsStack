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
	echo "Usage: getinstance.sh instanceID valuetoquery, such as ipaddress, hostname, status"
}

# if [ "$ARGUMENT" == "ipaddress" ]; then
# aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress"
# fi

if [ $# -gt 1 ]; then
aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].${ARGUMENT}"
fi


# if [ $# -eq 10 ]; then

# 	instances=$(aws ec2 describe-instances | grep "INSTANCES" | grep $instanceID)

# 	# 					
# 	if [ "$ARGUMENT" == "ipaddress" ]; then
# 	#12 ip address
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[12]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin

# 	# PublicIpAddress
# 	elif [ "$ARGUMENT" == "ipaddresspublic" ]; then
# 	#11 hostname
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[14]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin

# 	#hostnamepublic
# 	elif [ "$ARGUMENT" == "hostnamepublic" ]; then
# 	#11 hostname
# 		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[13]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin

# 	elif [ "$ARGUMENT" == "hostname" ]; then
# 	#11 hostname
# 		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[11]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin

# 	# status
# 	elif [ "$ARGUMENT" == "status" ]; then
# 		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		
# 		instances=$(aws ec2 describe-instance-status --instance-ids $instanceID | grep "INSTANCESTATE")
		
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[2]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin

# 	elif [ "$ARGUMENT" == "reachability" ]; then
# 		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		
# 		instances=$(aws ec2 describe-instance-status --instance-ids $instanceID | grep "DETAILS\treachability")
		
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[2]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin

# 	#aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].State.Name"
# 	elif [ "$ARGUMENT" == "systemstatus" ]; then		
# 		instances=$(aws ec2 describe-instance-status --instance-ids $instanceID | grep "SYSTEMSTATUS")
		
# 		IFS=$'\n'
# 		for line in $instances
# 		do
# 			#echo $line
# 			IFS=$'\t'
# 			tmp=($line)
# 			var="${tmp[1]}"
# 			echo $var
# 		done | paste -s -d, /dev/stdin
# 	else
# 		#print_error
# 	fi
# 	#print_error
# fi

