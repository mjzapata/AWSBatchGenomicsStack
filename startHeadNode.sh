#!/bin/bash

#This is a script that gets pushed to the head node


docker pull mjzapata2/nextflow:latest

HOSTFLOWPATH=/mnt/efs/flows
CONTAINERFLOWPATH=/flows

HOSTREPORTPATH=/mnt/efs/reports
CONTAINERREPORTPATH=/reports

IMAGENAME=mjzapata2/nextflow

#/usr/local/bin/nextflow (in the container)
ENTRYPOINT=/usr/local/bin/nextflow
#COMMAND=

docker run --rm -it --name nextflow -v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} -v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} --entrypoint "$ENTRYPOINT" $IMAGENAME -c 'run /flows/main.nf -c /flows/nextflow.config -with-trace reports/tracename -with-timeline reports/timelinefilename.html -with-dag reports/flowchart.html -w s3://mytestbucketmz123/2018_01_17_testNextflowNode'

#docker run --rm -it --name nextflow -v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} -v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} --entrypoint "/bin/bash" $IMAGENAME
#docker run --rm -it --name nextflow -v ${HOSTFLOWPATH}:${CONTAINERFLOWPATH} -v ${HOSTREPORTPATH}:${CONTAINERREPORTPATH} --entrypoint "ls" $IMAGENAME -c '/flows'




