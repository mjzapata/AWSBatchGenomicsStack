#!/bin/bash

#This is a script that gets pushed to the head node


IMAGENAME=mjzapata2/nextflow
docker pull ${IMAGENAME}:latest

#TODO: note this is hardcoded here AND in the main.nf
PROJECTNAME=testproj1
PROJECTDIR=/mnt/efs/${PROJECTNAME}

mkdir ${PROJECTDIR}

S3BUCKETNAME=mytestbucketmz123
S3BUCKETPATH=s3://${S3BUCKETNAME}/${PROJECTNAME}

HOSTFLOWPATH=/mnt/efs/flows/
CONTAINERFLOWPATH=/flows/
FLOWFILENAME=main.nf

HOSTREPORTPATH=/mnt/efs/reports/
CONTAINERREPORTPATH=/reports/


NEXTFLOWHOSTCONFIGDIRECTORY=~/.nextflow/
NEXTFLOWCONTAINERCONFIGDIRECTORY=/root/.nextflow/

AWSHOSTCONFIGDIRECTORY=~/.aws/
AWSCONTAINERCONFIGDIRECTORY=/root/.aws/

TRACENAME=${CONTAINERREPORTPATH}mytracename
TIMELINENAME=${CONTAINERREPORTPATH}mytimelinefilename.html
FLOWCHARTNAME=${CONTAINERREPORTPATH}myflowchart.html

#/usr/local/bin/nextflow (in the container)
#ENTRYPOINT=/usr/local/bin/nextflow
ENTRYPOINT=nextflow


# bash trick with single and double quotes to get the COMMAND to be seen as a single argument
COMMAND="' run . \
-c nextflow.config \
-with-trace ${TRACENAME} \
-with-timeline ${TIMELINENAME} \
-with-dag ${FLOWCHARTNAME} \
-w ${S3BUCKETPATH}'"

#https://stackoverflow.com/questions/13799789/expansion-of-variable-inside-single-quotes-in-a-command-in-bash
#docker run --rm -it --name nextflow \
#-v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} \
#-w ${CONTAINERFLOWPATH} \
#-v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} \
#-v ${NEXTFLOWHOSTCONFIGDIRECTORY}:${NEXTFLOWCONTAINERCONFIGDIRECTORY} \
#-v ${AWSHOSTCONFIGDIRECTORY}:${AWSCONTAINERCONFIGDIRECTORY} \
#--entrypoint "nextflow" $IMAGENAME -c $COMMAND


docker run --rm -it --name nextflow \
-v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} \
-v /mnt/efs/${PROJECTNAME}:/efs/${PROJECTNAME} \
-w ${CONTAINERFLOWPATH} \
-v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} \
-v ${NEXTFLOWHOSTCONFIGDIRECTORY}:${NEXTFLOWCONTAINERCONFIGDIRECTORY} \
-v ${AWSHOSTCONFIGDIRECTORY}:${AWSCONTAINERCONFIGDIRECTORY} \
--entrypoint "/bin/bash" $IMAGENAME -c "nextflow run . -w s3://mytestbucketmz123/2019_04_17_testNextflowNode"


#COMMAND='run /flows/main.nf -c /flows/nextflow.config -with-trace
# reports/tracename -with-timeline reports/timelinefilename.html
# -with-dag reports/flowchart.html -w s3://mytestbucketmz123/2018_01_17_testNextflowNode'

#--entrypoint "$ENTRYPOINT" $IMAGENAME -c 'run /flows/main.nf -c #
#'"${NEXTFLOWCONTAINERCONFIGDIRECTORY}/config"' -with-trace reports/tracename
# -with-timeline reports/timelinefilename.html -with-dag reports/flowchart.html
# -w s3://mytestbucketmz123/2018_01_17_testNextflowNode'

#docker run --rm -it --name nextflow -v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} #
#-v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} --entrypoint "$ENTRYPOINT" $IMAGENAME -c $COMMAND
# docker run --rm -it --name nextflow -v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} \
# -v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} \
# -v ${NEXTFLOWHOSTCONFIGDIRECTORY}:${NEXTFLOWCONTAINERCONFIGDIRECTORY} \
# -v ${AWSHOSTCONFIGDIRECTORY}:${AWSCONTAINERCONFIGDIRECTORY} \
# --entrypoint "${ENTRYPOINT}" $IMAGENAME -c ' run /flows/main.nf -c /root/.nextflow/config -with-trace reports/tracename -with-timeline reports/timelinefilename.html -with-dag reports/flowchart.html -w s3://mytestbucketmz123/2018_01_25_testNextflowNode'

#COMMAND= run /flows/main.nf -c /root/.nextflow/config -with-trace reports/tracename -with-timeline reports/timelinefilename.html -with-dag reports/flowchart.html -w s3://mytestbucketmz123/2018_01_25_testNextflowNode