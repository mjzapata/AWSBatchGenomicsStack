#!/bin/bash

#This script write a job definition in YAML
#The job definition supplments the primary nextflow 
#script by allowing to run priveledged containers
#and mounting the EFS in a location that docker can reach it.
#This was the only way to get EFS to mount at boot time.

if [ $# -gt 4 && $# -lt 7 ]; then

	JOBDEFINITIONNAME=$1
	IMAGE=$2
	JOBEROLEARN=$3
	VCPUS=$4
	MEMORY=$5

	if [ $# -eq 6 ]; then
		COMMAND=$6
	else
		COMMAND=/bin/bash
	fi

	#1.) Check for existence of JOBDEFINITIONNAME

	jobdefwordcount=$(aws batch describe-job-definitions | grep JOBDEFINITIONS | grep ${JOBDEFINITIONNAME} | wc -m)

	if [[ jobdefwordcount -gt 1 ]]; then
		echo "job exists"
	else

	echo "
JobDefinition:
  Type: AWS::Batch::JobDefinition
  Properties:
    Type: container
    JobDefinitionName: ${JOBDEFINITIONNAME}
    ContainerProperties:
      MountPoints:
        - ReadOnly: false
          SourceVolume: efs
          ContainerPath: /efs
      Volumes:
        - Host:
            SourcePath: /mnt/efs
          Name: efs
      Command:
        - ${COMMAND}
      Memory: ${MEMORY}
      Privileged: true
      JobRoleArn: ${JOBROLEARN}
      ReadonlyRootFilesystem: true
      Vcpus: ${VCPUS}
      Image: ${IMAGE}
" 
	containerProperties="{"image": "${IMAGE}", "vcpus": $VCPUS, "memory": $MEMORY, "command": ["${COMMAND}"]}"

	CONTAINERPATH=/efs

	VOLUMESOURCEPATH=/mnt/efs
	VOLUMENAME=efs

containerProperties="{
  \"image\": \"$IMAGE\",
  \"vcpus\": $VCPUS,
  \"memory\": $MEMORY,
  \"command\": [\"$COMMAND\"],
  \"jobRoleArn\": \"$JOBROLEARN\",
  \"volumes\": [
    {
      \"host\": {
        \"sourcePath\": \"${VOLUMESOURCEPATH}\"
      },
      \"name\": \"${VOLUMENAME}\"
    }
  ],
  \"mountPoints\": [
    {
      \"containerPath\": \"${CONTAINERPATH}\",
      \"readOnly\": false,
      \"sourceVolume\": \"${VOLUMENAME}\"
    }
  ],
  \"readonlyRootFilesystem\": false,
  \"privileged\": true
}"

	jobRegisterOutpu=$(aws batch register-job-definition --job-definition-name $JOBDEFINITIONNAME --type container --container-properties ${containerProperties})



	fi

fi

