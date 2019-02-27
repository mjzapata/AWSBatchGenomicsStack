#!/bin/bash

#derived from: https://gist.github.com/pahud/aab838a0a3a9db857d822fe1f222683c 

if [ $# -eq 4 ]; then

	REGION=$1
	QUERYSTRING=$2
	YEAR=$3
	ARCHITECTURE=$4

	#aws --region $REGION ec2 describe-images --owner amazon --query 'Images[?Name!=`null`]|[?contains(Name, `'$QUERYSTRING'`) == `true`]|[?contains(Name, to_string(`'$YEAR'`)) == `true`]|[0:4].[Name,ImageId,CreationDate,Description]' --output text | sort -rk1
	aws --region $REGION ec2 describe-images --owner amazon --query 'Images[?Name!=`null`]|[?contains(Name, `'$QUERYSTRING'`) == `true`]|[?contains(Name, `'$ARCHITECTURE'`) == `true`]|[?contains(Name, to_string(`'$YEAR'`)) == `true`]|[0:1].[ImageId]' --output text | sort -rk1

else

echo "This script finds the latest amazon ami and returns the AMI image ID.
Usage example: 
getLatestAMI.sh us-east-1 amzn2-ami-ecs-hvm 2019 x86_64"

fi

