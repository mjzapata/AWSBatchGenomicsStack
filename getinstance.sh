#!/bin/bash

instanceID=$1
ARGUMENT=$2


if [ $# -eq 2 ]; then

	instances=$(aws ec2 describe-instances | grep "INSTANCES" | grep $instanceID)

	if [ "$ARGUMENT" == "ipaddress" ]; then
	#12 ip address
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[12]}"
			echo $var
		done | paste -s -d, /dev/stdin

	elif [ "$ARGUMENT" == "ipaddresspublic" ]; then
	#11 hostname
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[14]}"
			echo $var
		done | paste -s -d, /dev/stdin

	#hostnamepublic
	elif [ "$ARGUMENT" == "hostnamepublic" ]; then
	#11 hostname
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[13]}"
			echo $var
		done | paste -s -d, /dev/stdin

	elif [ "$ARGUMENT" == "hostname" ]; then
	#11 hostname
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[11]}"
			echo $var
		done | paste -s -d, /dev/stdin

	# status
	elif [ "$ARGUMENT" == "status" ]; then
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		
		instances=$(aws ec2 describe-instance-status --instance-ids $instanceID | grep "INSTANCESTATE")
		
		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[2]}"
			echo $var
		done | paste -s -d, /dev/stdin

	elif [ "$ARGUMENT" == "reachability" ]; then
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		
		instances=$(aws ec2 describe-instance-status --instance-ids $instanceID | grep "DETAILS\treachability")
		
		IFS=$'\n'
		for line in $instances
		do
			#echo $line
			IFS=$'\t'
			tmp=($line)
			var="${tmp[2]}"
			echo $var
		done | paste -s -d, /dev/stdin

	elif [ "$ARGUMENT" == "systemstatus" ]; then
		#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
		
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
		echo "Usage: ./getinstance.sh instanceID valuetoquery, such as ipaddress, hostname, status"
	fi


else
	echo "Usage: "
fi