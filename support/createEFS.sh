#!/bin/bash
#creates an elastic filesystem with the same name as the stack
#THIS SCRIPT IS NOT USED IN THE MAIN PIPELINE ANYMORE.  Only here for experimental purposes.

#to delete a filesystem:
#efsID=$(createEFS.sh describe $EFSCREATIONTOKEN)
#createEFS.sh delete $efsID

ARGUMENT=$1
if [ $# -gt 1 ]; then
	EFSCREATIONTOKEN=$2
	if [ $ARGUMENT == "describe" ]; then
		efsoutput=$(aws efs describe-file-systems --creation-token $EFSCREATIONTOKEN)
		efsID=$(echo $efsoutput | awk '//{print $5}')
		echo $efsID

	elif [ $ARGUMENT == "create" ]; then
		EFSPERFORMANCEMODE=$3
		EFSTHROUGHPUTMODE=$4
		EFSENCRYPTEDMODE=$5
		EFSTAG=$6
		EFSTAGVALUE=$7
		efsoutput=$(aws efs create-file-system \
		--creation-token $EFSCREATIONTOKEN \
		--performance-mode $EFSPERFORMANCEMODE \
		--throughput-mode $EFSTHROUGHPUTMODE \
		$EFSENCRYPTEDMODE )

		efsID=$(echo $efsoutput | awk '//{print $4}')
		echo $efsID

		#TODO: add tags
	elif [ $ARGUMENT == "create" ]; then
		efsID=$2
		efsoutput=$(aws efs delete-file-system --file-system-id $efsID)
		echo $efsoutput
		"deleted filesystem:  $efsID"
	elif [[ $ARGUMENT="createMountTarget" ]]; then
		efsID=$2
		efsSubnetTarget=$3
		efsSecurityGroupTarget=$4
		mountOutput=$(aws efs create-mount-target \
			--file-system-id $efsID \
			--subnet-id $efsSubnetTarget \
			--security-groups $efsSecurityGroupTarget)
		#POSSIBLE MOUNT TARGET STATE: Creating, available

		echo $mountOutput
	else
		echo "usage: "
		echo "usage: createEFS.sh describe [EFSCREATIONTOKEN]  (returns efsID)"
		echo "usage: createEFS.sh create EFSCREATIONTOKEN EFSPERFORMANCEMODE EFSTHROUGHPUTMODE EFSENCRYPTEDMODE EFSTAG EFSTAGVALUE"
		echo "usage: createEFS.sh delete efsID"
	fi
else
	echo "usage: "
	echo "usage: createEFS.sh describe [EFSCREATIONTOKEN]  (returns efsID)"
	echo "usage: createEFS.sh create EFSCREATIONTOKEN EFSPERFORMANCEMODE EFSTHROUGHPUTMODE EFSENCRYPTEDMODE EFSTAG EFSTAGVALUE"
	echo "usage: createEFS.sh delete efsID"
fi

