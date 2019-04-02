#!/bin/bash

source ~/.batchawsdeploy/config

#1.) create S3 

STACKNAME=BLJStack

deployCloudInfrastructure.sh create $STACKNAME "biolockj/"

echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"

EC2Node.sh runscript_detached $STACKNAME HeadNode t2.micro startHeadNodeGui.sh


echo "to shut this stack and instance down run: 
deployCloudInfrastructure.sh delete $STACKNAME "
echo "-------------------------------------------------------------"