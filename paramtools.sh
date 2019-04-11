#!/bin/bash

ARGUMENT=$1
STACKNAME=$2
PARAM3=$3
PARAM4=$4




aws ssm put-parameter --name bioshepherd_stack_${STACKNAME}_myinstancename

aws ssm put-parameter --name bioshepherd.stack.${STACKNAME}._myinstancename2 \
	--value "BBBBBBBBBBB\nAAAAAAA" --type String


aws ssm describe-parameters --output table

#get parameter

#get stack

#for each stack 

#for each instance...

test=$(aws ssm get-parameter --name bioshepherd_stack_${STACKNAME} --query Parameter.Value)

aws ssm get-parameter --name bioshepherd_instance_${instanceName}_
#get instance


