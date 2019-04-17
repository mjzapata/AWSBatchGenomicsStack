#!/bin/bash

source ~/.batchawsdeploy/config

print_error(){
echo "Usage:
	autoDeployStackAndHeadNode.sh
		uses the default values: BLJStack biolockj/ t2.micro runscript_detached startHeadNodeGui.sh
	autoDeployStackAndHeadNode.sh STACKNAME DOCKERREPONAME INSTANCETYPE EC2RUNARGUMENT SCRIPTNAME
		EC2RUNARGUMENT options: directconnect, runscript_detached, runscript_attached
	"
}

STACKNAME=$1
DOCKERREPONAME=$2
INSTANCETYPE=$3
EC2RUNARGUMENT=$4
SCRIPTNAME=$5

NODENAME=HeadNode

[ -z "$STACKNAME" ] && STACKNAME=BLJStack
#	STACKNAME=BLJStack
#	echo "STACKNAME=$STACKNAME"
#fi
[ -z "$DOCKERREPONAME" ] && DOCKERREPONAME=biolockj/
# 	DOCKERREPONAME=biolockj/
# 	echo "DOCKERREPONAME=$DOCKERREPONAME"
# fi
[ -z "$INSTANCETYPE" ] && INSTANCETYPE=t2.micro 
# 	INSTANCETYPE=t2.micro
# 	echo "INSTANCETYPE=$INSTANCETYPE"
# fi
[ -z "$EC2RUNARGUMENT" ] && EC2RUNARGUMENT=runscript_detached 
# 	EC2RUNARGUMENT=runscript_detached
# 	echo "EC2RUNARGUMENT=$EC2RUNARGUMENT"
# fi
echo "STACKNAME=$STACKNAME"
echo "DOCKERREPONAME=$DOCKERREPONAME"
echo "INSTANCETYPE=$INSTANCETYPE"
echo "EC2RUNARGUMENT=$EC2RUNARGUMENT"

if [ -z "$SCRIPTNAME" ] && [ "$EC2RUNARGUMENT" != "directconnect" ]; then 
	SCRIPTNAME=startHeadNodeGui.sh
	echo "SCRIPTNAME=$SCRIPTNAME"
fi


if [ "$STACKNAME" == "help" ] || [ "$STACKNAME" == "--help" ] || [ "$STACKNAME" == "-h" ]; then
	print_error
	break;
fi

#1.) TODO: create S3 here instead

deployCloudInfrastructure.sh create $STACKNAME "$DOCKERREPONAME"

echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"

if [ "$EC2RUNARGUMENT" == "directconnect" ] || [ "$EC2RUNARGUMENT" == "runscript_detached" ] || [ "$EC2RUNARGUMENT" == "runscript_attached" ]; then
	
	#if [ "$EC2RUNARGUMENT" == "directconnect" ]; then 
	EC2Node.sh $EC2RUNARGUMENT $STACKNAME $NODENAME $INSTANCETYPE $SCRIPTNAME
	echo "to shut this stack and instance down run: "
	echo "	deployCloudInfrastructure.sh delete $STACKNAME "
	echo "-------------------------------------------------------------"
	# elif [ "$EC2RUNARGUMENT" == "runscript_detached" ] || [ "$EC2RUNARGUMENT" == "runscript_attached" ]; then

	# 	EC2Node.sh $EC2RUNARGUMENT $STACKNAME HeadNode $INSTANCETYPE $SCRIPTNAME
	# 	echo "to shut this stack and instance down run: "
	# 	echo "	deployCloudInfrastructure.sh delete $STACKNAME "
	# 	echo "-------------------------------------------------------------"
	#fi


else
	echo "not a valid EC2RUNARGUMENT"
fi






