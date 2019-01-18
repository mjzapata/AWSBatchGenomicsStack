#!/bin/bash
#usage: 
	#./printnextflowconfig.sh $imageID $QUEUENAME 
	#./printnextflowconfig.sh $imageID $QUEUENAME $efsID

QUEUENAME=$1
AWSACCESSKEY=$2
AWSSECRETKEY=$3

#Without EFS
if [ $# -eq 3 ]; then
echo ""
echo "
executor {
    name = 'awsbatch'
    awscli = '/home/ec2-user/miniconda/bin/aws'
}
process {
    queue = $QUEUENAME
}
aws {
    accessKey = '$AWSACCESSKEY'
    secretKey = '$AWSSECRETKEY'
    region = 'us-east-1'
}
"
echo ""
else
    echo "error, usage: ./printnextflowconfig QUEUENAME AWSACCESSKEY AWSSECRETKEY"
fi

