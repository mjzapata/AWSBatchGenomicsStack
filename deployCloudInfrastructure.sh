#!/bin/bash
#TODO: test stack create failure

#TODO: Test that the IP addresss is getting assigned correctly
#TODO: test that S3 is getting created correctly in both cases

#need to capture output from each step and check for success?

#also check if there are currently any instances using any of these resources?
#get the ID and tell them to run the shutdown
#AWS_PROFILE=batchcompute

#1.) CHECK THAT INSTALL SCRIPT HAS BEEN RUN
if [ ! -f ~/.batchawsdeploy/config ]; then
    echo "~/.batchawsdeploy/config does not exist"
    echo "did you run installBatchDeployer.sh?"
    exit 1
fi
source ~/.batchawsdeploy/config

#2.) CHECK AWS VERSION
configAWScredentials.sh version

#3.) CHECK AWS CREDENTIALS
configAWScredentials.sh validate

ARGUMENT=$1

print_help() {
    echo "-This script deploys an Amazon Web Services (AWS) cloudformation stack and 
    other resources necessary for using AWS Batch.  This script also saves the
    configuration of this stack to the local hidden directories:
    \"~/.batchawsdeploy/\", \"~/.aws/\", and \"~/.nextflow/\""
    echo "-The dockerhub repository name creates the priviledged job definitions
    for nextflow.  These are necessary for EFS mounts. For multuple docker hub 
    repositories use the | pipe operator WITH QUOTES as shown below."
    echo "Run this command to test your results: docker search mydockerhubreponame | grep -E mydockerhubreponame"
    echo ""
    echo "-When the resources are no longer needed, run the delete command."
    echo "MYSTACKNAME must be alphanumeric.  No underscores."
    echo ""
    echo "Usage: deployCloudinfastructure.sh help"
    echo "Usage: deployCloudinfastructure.sh create MYSTACKNAME mydockerhubreponame1" #autogenerate"
    echo "Usage: deployCloudinfastructure.sh create MYSTACKNAME mydockerhubreponame1" #MYS3BUCKETNAME"
    echo -n "Usage: deployCloudinfastructure.sh create MYSTACKNAME "
    echo "\"mydockerhubreponame1,mydockerhubreponame2,mydockerhubreponame3\"" #MYS3BUCKETNAME"
    echo "Usage: deployCloudinfastructure.sh delete MYSTACKNAME"
    echo ""
    echo "error: $1"
    exit 1
}

echo "ARGUMENT: $ARGUMENT"

if [ "$ARGUMENT" == "help" ] || [ "$ARGUMENT" == "--help" ] || [ "$ARGUMENT" == "-h" ]; then
    print_help
else
    if [ "$ARGUMENT" == "create" ] || [ "$ARGUMENT" == "delete" ]; then
        STACKNAME=$2
        echo "STACKNAME: $STACKNAME"

        # Job Definition
        DOCKERREPOSEARCHSTRING=$3
        
        #optional S3BUCKETNAME if it isn't created beforehand
        S3BUCKETNAME=$4
        
        DOCKERREPOVERSION="latest"
        JOBVCPUS=2      #can be overridden at runtime
        JOBMEMORY=1000  #can be overriden at runtime

        #COMPUTEENVIRONMENTNAME=${STACKNAME}-ComputeEnvSpot
        #QUEUENAME=${STACKNAME}-LowPriorityQueue
        SPOTPERCENT=80
        MAXCPU=1024
        EBSVOLUMESIZEGB=0

        REGION=$(aws configure get region)

        CUSTOMAMIFOREFS="no"
        EFSPERFORMANCEMODE=maxIO  #or generalPurpose

        #NEXTFLOWHOME
        NEXTFLOWCONFIGOUTPUTDIRECTORY=~/.nextflow/
        mkdir -p $NEXTFLOWCONFIGOUTPUTDIRECTORY
        
        #AWS_HOME
        mkdir -p ~/.aws/

        KEYNAME=${STACKNAME}
        KEYPATH=~/.batchawsdeploy/key_${KEYNAME}.pem

        #Can check if this file already exists before proceeding?
        BATCHAWSCONFIGFILE=~/.batchawsdeploy/stack_${STACKNAME}.sh
        echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE"

        #S3 buckets will NOT be deleted when running "deployBLJBatchEnv delete"
        #autogenerate is a keyword that creates a bucket named ${STACKNAME}{randomstring}, 
        #    eg. Stack1_oijergoi4itf94j94

    	if [ "$ARGUMENT" == "create" ] && [ $# -gt 2 ] && [ $# -lt 5 ]; then
            
            echo "Finding Latest Amazon Linux AMI ID..."
            #TODO: if is-empty, set a default, in case this breaks in the future. 
            DEFAULTAMI=ami-007571470797b8ffa
            #DEFAULTAMI=$(getLatestAMI.sh $REGION amzn2-ami-ecs-hvm 2019 x86_64)
            echo "DEFAULTAMI=$DEFAULTAMI"
            echo ""

            #Create AWS config file and start writing values
            #this is duplicated in s3Tools.sh and deployBatchEnv.sh
            if [ ! -f $BATCHAWSCONFIGFILE ]; then
                touch "$BATCHAWSCONFIGFILE"
                echo "#!/bin/bash" > $BATCHAWSCONFIGFILE
                echo "" >> $BATCHAWSCONFIGFILE
                echo "BATCHAWSCONFIGFILE=$BATCHAWSCONFIGFILE" >> $BATCHAWSCONFIGFILE
                echo "REGION=$REGION" >> $BATCHAWSCONFIGFILE
            fi

            #echo "AWS_PROFILE=$AWS_PROFILE" >> $BATCHAWSCONFIGFILE
            echo "DOCKERREPOSEARCHSTRING=\"$DOCKERREPOSEARCHSTRING\"" >> $BATCHAWSCONFIGFILE
            echo "DOCKERREPOVERSION=$DOCKERREPOVERSION" >> $BATCHAWSCONFIGFILE
            echo "JOBVCPUS=$JOBVCPUS" >> $BATCHAWSCONFIGFILE
            echo "JOBMEMORY=$JOBMEMORY" >> $BATCHAWSCONFIGFILE
            echo "NEXTFLOWCONFIGOUTPUTDIRECTORY=$NEXTFLOWCONFIGOUTPUTDIRECTORY" >> $BATCHAWSCONFIGFILE

          echo "COMMAND BEING RUN: 
        createRolesAndComputeEnv.sh $STACKNAME $SPOTPERCENT $MAXCPU \
                    $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE \
                    $NEXTFLOWCONFIGOUTPUTDIRECTORY $KEYNAME"
    	   createRolesAndComputeEnv.sh $STACKNAME $SPOTPERCENT $MAXCPU \
                    $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE \
                    $NEXTFLOWCONFIGOUTPUTDIRECTORY $KEYNAME \
                    || { echo "deploycloudinfastructure CREATE_FAILED"; exit 1; }

    	elif [ "$ARGUMENT" == "delete" ] && [ $# -gt 1 ]; then
            echo "this will take approximately three minutes:"
            #echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME"
            
            source $BATCHAWSCONFIGFILE
            # TODO: check for running EC2 instances
            #instanceFiles=~/.batchawsdeploy/instance_${STACKNAME}*
            #instanceFiles=$(~/.batchawsdeploy/instance_${STACKNAME}*)

            # TODO: Check for network interfaces
            # aws ec2 describe-network-interfaces --filters Name=group-id,Values=sg-0fb51f0752d394c02,
            # research how to use query vs filter: 
            # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-network-interfaces.html
            # DESCRIPTION
            # Network interface for Bastion Node
            # EFS mount target for fs-56d23cb6 (fsmt-42d00fa3)
            
            #echo "deleting job queue $QUEUENAME"
            #batchTools.sh queue disableAndDelete $QUEUENAME

            #delete compute environment which is dependent on queue
            
            #echo "deleting compute environment $COMPUTEENVIRONMENTNAME"
            #batchTools.sh compute disableAndDelete $COMPUTEENVIRONMENTNAME

            #delete job definition
            # aws batch deregister-job-definition
            # get a list of all jobdefs that start with $STACKNAME
            echo "deleting cloudformation stack $STACKNAME"
            aws cloudformation delete-stack --stack-name $STACKNAME

            stackstatus=$(getcloudformationstack.sh $STACKNAME)
            maxloop=15
            loopnum=0
            while [ "$stackstatus" != "NO_SUCH_STACK" ] && [ "$loopnum" -lt "$maxloop" ]
            do
                sleep 10
                loopnum=$(expr $loopnum + 1)
                #echo "loopnum=$loopnum"
                stackstatus=$(getcloudformationstack.sh $STACKNAME)
                #echo "stackstatus=$stackstatus"
            done

            awskeypair.sh delete $KEYNAME

            rm $BATCHAWSCONFIGFILE
            #rm ${NEXTFLOWCONFIGOUTPUTDIRECTORY}config

            #TODO: change to while loop
            stackstatus=$(getcloudformationstack.sh $STACKNAME)
            if [ "$stackstatus" == "NO_SUCH_STACK" ]; then 
                echo "stackstatusFinal=$stackstatus"
                echo "DELETE_COMPLETE"
            else
                echo "----------------------------------------------"
                echo "For more information please see:"
                echo "https://console.aws.amazon.com/cloudformation/"
                echo "DELETE_FAILED"
            fi
        else
            print_help
    	fi
    else
        print_help "error: first argument must be: create, delete, or help"
    fi
fi
