#!/bin/bash

# Returns "available" if the image is available

if [ $# -eq 2 ]; then

	IMAGEID=$1
	ARGUMENT=$2
	if [ "$ARGUMENT" == "status" ]; then
		statuspending=$(aws ec2 describe-images --image-ids $IMAGEID | grep -c pending)
		statusavailable=$(aws ec2 describe-images --image-ids $IMAGEID | grep -c available)

		if [ $statusavailable -gt 0 ]; then
			echo "available"
		elif [[ $statuspending -gt 0 ]]; then
			echo "pending"
		else
			echo "image not found"
		fi

	else
		echo "Usage:  ./getec2images.sh [imageID] [argument]"
		echo "Usage:  ./getec2images.sh tags [imagetag] [imagetagvalue]"

	fi

elif [ $# -gt 2 ]; then
	ARGUMENT=$1

	if [[ "$ARGUMENT" == "tags" ]]; then
		IMAGETAG=$2
		IMAGETAGVALUE=$3
		aws ec2 describe-images --filters "Name=tag:$IMAGETAG,Values=$IMAGETAGVALUE"
	else
		echo "Usage:  ./getec2images.sh [imageID] [argument]"
		echo "Usage:  ./getec2images.sh tags [imagetag] [imagetagvalue]"
	fi

else
	echo "Usage:  ./getec2images.sh [imageID] [argument]"
	echo "Usage:  ./getec2images.sh tags [imagetag] [imagetagvalue]"

fi

