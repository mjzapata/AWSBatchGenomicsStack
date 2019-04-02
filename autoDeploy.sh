#!/bin/bash

source ~/.batchawsdeploy/config

#1.) create S3 

STACKNAME=BLJStack

deployCloudInfrastructure.sh create $STACKNAME "biolockj/"

echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"

EC2Node.sh runscript_detached $STACKNAME HeadNode t2.micro startHeadNodeGui.sh


