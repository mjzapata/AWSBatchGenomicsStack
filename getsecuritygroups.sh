#!/bin/bash

#TODO: what else could this possibly look like?? in my account there's only one security group...


#TODO: look at full output of aws aws ec2 describe-security-groups 
# to determine which security groups have the necessary permissions??
# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IpPermission.html 

secgroups=$(aws ec2 describe-security-groups | grep "SECURITYGROUPS")
IFS=$'\n'
for line in $secgroups
do
	#echo line
	IFS=$'\t'
	tmp=($line)
	securitygroup="${tmp[2]}"
	echo $securitygroup
done | paste -s -d, /dev/stdin


