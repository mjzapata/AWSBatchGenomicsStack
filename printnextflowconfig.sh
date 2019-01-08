#!/bin/bash
#usage: 
	#./printnextflowconfig.sh $imageID $QUEUENAME 
	#./printnextflowconfig.sh $imageID $QUEUENAME $efsID

imageID=$1
QUEUENAME=$2
efsID=$3

#Without EFS
if [ $# -eq 2 ]; then
echo "copy and paste this into a file named nextflow.config and change the values for accessKey and secretKey"
echo ""
echo "
executor {
    name = 'awsbatch'
    awscli = '/home/ec2-user/miniconda/bin/aws'
}
cloud{
	imageId = '$imageID'
}
aws {
    accessKey = 'mysecretaccesskeyid'
    secretKey = 'mysecretkey'
    region = 'us-east-1'
}
"
echo ""
fi
#With EFS
if [ $# -eq 3 ]; then
echo "copy and paste this into a file named nextflow.config and change the values for accessKey and secretKey"
echo ""
echo "
executor {
    name = 'awsbatch'
    awscli = '/home/ec2-user/miniconda/bin/aws'
}
cloud{
	imageId = '$imageID'
	sharedStorageId = '$efsID'
	sharedStorageMount = '/mnt/efs'
}
aws {
    accessKey = 'mysecretaccesskeyid'
    secretKey = 'mysecretkey'
    region = 'us-east-1'
}
"
echo ""
fi


