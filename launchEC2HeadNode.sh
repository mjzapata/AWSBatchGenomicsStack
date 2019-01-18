#!/bin/bash

#this script launches a head node for submitting batch jobs to AWS

# use same cloud-init
# only launchable after compute environment is setup?
# set e-mail notifications

#TODO:
# script to enable the head node to be accessed from only select IPs
# run the script once from a new IP
# seperate instance for displaying data or just a seperate docker image?
# seperate port for management console?



#LAUNCH HEAD NODE WITH SCRIPT
#./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB $AMIIDENTIFIER $IMAGETAG $IMAGETAGVALUE $SUBNETS $BASTIONSECURITYGROUP $MYPUBLICIPADDRESS $EC2RUNARGUMENT startHeadNode.sh 
EC2RUNARGUMENT=runscript
SCRIPTNAME="startHeadNode.sh"
INSTANCENAME="HeadNode"
INSTANCETYPE=t2.micro
IMAGEID=ami-05422e32bf76f947c
EBSVOLUMESIZEGB=0

./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB $SUBNETS $SECURITYGROUPS $MYPUBLICIPADDRESS $INSTANCENAME $EC2RUNARGUMENT $LAUNCHTEMPLATEID $SCRIPTNAME


#DIRECTCONNECT
EC2RUNARGUMENT=directconnect

INSTANCETYPE=t2.micro
IMAGEID=ami-05422e32bf76f947c
EBSVOLUMESIZEGB=0
INSTANCENAME="HeadNode"

SUBNETS=$(./getcloudformationstack.sh $STACKNAME Subnet)  #replaced getsubnets
BASTIONSECURITYGROUP=$(./getcloudformationstack.sh $STACKNAME BastionSecurityGroup)
BATCHSECURITYGROUP=$(./getcloudformationstack.sh $STACKNAME BatchSecurityGroup)
SECURITYGROUPS="$BASTIONSECURITYGROUP,$BATCHSECURITYGROUP"

LAUNCHTEMPLATEID=lt-01473bb551ec95911

# AMIIDENTIFIER=null
# IMAGETAG=null
# IMAGETAGVALUE=null
./launchEC2.sh $STACKNAME $IMAGEID $INSTANCETYPE $KEYNAME $EBSVOLUMESIZEGB $SUBNETS $SECURITYGROUPS $MYPUBLICIPADDRESS $INSTANCENAME $EC2RUNARGUMENT $LAUNCHTEMPLATEID




