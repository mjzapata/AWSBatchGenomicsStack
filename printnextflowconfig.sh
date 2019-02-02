#!/bin/bash
#usage: 
#./printnextflowconfig AWSCONFIGFILENAME

#resources:
#https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
#Without EFS

if [ $# -eq 1 ]; then
AWSCONFIGFILENAME=$1
source $AWSCONFIGFILENAME

echo ""
echo "
executor {
    name = 'awsbatch'
    //awscli = '/home/ec2-user/miniconda/bin/aws'
}
process {"
images=$(grep "image_" $AWSCONFIGFILENAME)
	echo "    queue = '$QUEUENAME'"
while read -r line; do
	IFS='=' read -d '' -ra array < <(printf '%s\0' "$line")
	echo "    withLabel: ${array[0]} {"
	echo "        container = '${array[1]}'"
	echo "    }"
done <<< "$images"

echo "}
aws {
    region = '$REGION'
}
"
echo ""

else
    echo "error, usage: ./printnextflowconfig AWSCONFIGFILENAME"
fi

