#!/bin/bash

#This script write a job definition in YAML
#The job definition supplments the primary nextflow 
#script by allowing to run priveledged containers
#and mounting the EFS in a location that docker can reach it.
#This was the only way to get EFS to mount at boot time.
#JOBIMAGENOSPECIAL not currently used.

if [[ $# -gt 4 && $# -lt 7 ]]; then

	JOBDEFINITIONNAME=$1
	JOBIMAGE=$2
  JOBIMAGENOSPECIAL=$3
	JOBROLEARN=$4
	JOBVCPUS=$5
	JOBMEMORY=$6

	if [ $# -eq 6 ]; then
		COMMAND=$6
		echo "COMMAND=$COMMAND"
	else
		COMMAND=/bin/bash
		echo "COMMAND=$COMMAND"
	fi

	#1.) Check for existence of JOBDEFINITIONNAME
	#instead of checking, just register a new definitino and it will export the revision number
	CONTAINERPATH=/efs

	VOLUMESOURCEPATH=/mnt/efs
	VOLUMENAME=efs


containerProperties="{
  \"image\": \"$JOBIMAGE\",
  \"vcpus\": $JOBVCPUS,
  \"memory\": $JOBMEMORY,
  \"command\": [\"$COMMAND\"],
  \"jobRoleArn\": \"${JOBROLEARN}\",
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
echo "containerProperties:"
echo $containerProperties
echo ""

	jobRegisterOutput=$(aws batch register-job-definition --job-definition-name $JOBDEFINITIONNAME --type container --container-properties "${containerProperties}")
	echo $jobRegisterOutput

#	fi

fi

