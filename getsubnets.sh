#!/bin/bash

# TODO: read
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#VPC_Sizing 
subnets=$(aws ec2 describe-subnets)

#when IFS (reserved variable) is a value other than default, tmp=($roleline) gets parsed based on IFS
IFS=$'\n'
for line in $subnets
do
	#echo $line
	IFS=$'\t'
	tmp=($line)
	subnetID="${tmp[8]}"
	echo $subnetID
done | paste -s -d, /dev/stdin

#IFS=$'\t'
#tmp=($subnets)
#subnetID="${tmp[8]}"
#echo $subnetID


