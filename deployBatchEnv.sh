#!/bin/bash

#TODO: add progress bar
#need to capture output from each step and check for success?

#also check if there are currently any instances using any of these resources?
#get the ID and tell them to run the shutdown
#AWS_PROFILE=batchcompute

ARGUMENT=$1

print_help() {
    echo "-This script deploys an Amazon Web Services (AWS) cloudformation stack and 
    other resources necessary for using AWS Batch.  This script also saves the
    configuration of this stack to the local hidden directories:
    \"~/.aws/\" and \"~/.nextflow/\""
    echo "-The dockerhub repository name creates the priviledged job definitions
    for nextflow.  These are necessary for EFS mounts. For multuple docker hub 
    repositories use the | pipe operator WITH QUOTES as shown below."
    echo "Run this command to test your results: docker search mydockerhubreponame | grep -E mydockerhubreponame"
    echo ""
    echo "-When the resources are no longer needed, run the delete command."
    echo "MYSTACKNAME must be alphanumeric.  No underscores."
    echo ""
    echo "Usage: ./deployBLJBatchEnv.sh help"
    echo "Usage: ./deployBLJBatchEnv.sh create MYSTACKNAME mydockerhubreponame1"
    echo "Usage: ./deployBLJBatchEnv.sh create MYSTACKNAME \"mydockerhubreponame1|mydockerhubreponame2|mydockerhubreponame3\""
    echo "Usage: ./deployBLJBatchEnv.sh delete MYSTACKNAME"
    echo ""
}

if [ $ARGUMENT == "help" ] || [ $ARGUMENT == "--help" ] || [ $ARGUMENT == "-h" ]; then
    print_help
else

    if [ $ARGUMENT == "create" ] || [ $ARGUMENT == "delete" ]; then
        STACKNAME=$2

        # Job Definition
        DOCKERREPOSEARCHSTRING=$3
        S3BUCKETNAME=$4
        DOCKERRREPOVERSION="latest"
        JOBVCPUS=2      #can be overridden at runtime
        JOBMEMORY=1000  #can be overriden at runtime

        COMPUTEENVIRONMENTNAME=${STACKNAME}ComputeEnv
        QUEUENAME=${STACKNAME}Queue
        SPOTPERCENT=75
        MAXCPU=1024
        EBSVOLUMESIZEGB=0

        #hardcoded AMI value. set equal to "no" to create and use custom AMI size
        REGION=us-east-1

        CUSTOMAMIFOREFS="no"
        EFSPERFORMANCEMODE=maxIO  #or generalPurpose

        NEXTFLOWCONFIGOUTPUTDIRECTORY=~/.nextflow/
        mkdir -p $NEXTFLOWCONFIGOUTPUTDIRECTORY
        AWSCONFIGOUTPUTDIRECTORY=~/.aws/
        mkdir -p $AWSCONFIGOUTPUTDIRECTORY
        KEYNAME=${STACKNAME}KeyPair

        #Can check if this file already exists before proceeding?
        AWSCONFIGFILENAME=${AWSCONFIGOUTPUTDIRECTORY}${STACKNAME}.sh
        echo "AWSCONFIGFILENAME=$AWSCONFIGFILENAME"

        #S3 buckets will NOT be deleted when running "./deployBLJBatchEnv delete"
        #autogenerate is a keyword that creates a bucket named ${STACKNAME}{randomstring}, eg Stack1_oijergoi4itf94j94

    	if [ "$ARGUMENT" == "create" ] && [ $# -eq 4 ]; then
            
            #DEFAULTAMI=ami-06bec82fb46167b4f #IMAGES
            echo "Finding Latest Amazon Linux AMI ID..."
            #TODO: if is-empty, set a default, in case this breaks in the future. 
            DEFAULTAMI=$(./getLatestAMI.sh $REGION amzn2-ami-ecs-hvm 2019 x86_64)
            echo "DEFAULTAMI=$DEFAULTAMI"
            echo ""
            #Create AWS config file and start writing values
            touch "$AWSCONFIGFILENAME"
            echo "#!/bin/bash" > $AWSCONFIGFILENAME
            echo "" >> $AWSCONFIGFILENAME
            echo "AWSCONFIGFILENAME=$AWSCONFIGFILENAME" >> $AWSCONFIGFILENAME
            #echo "AWS_PROFILE=$AWS_PROFILE" >> $AWSCONFIGFILENAME
            echo "DOCKERREPOSEARCHSTRING=\"$DOCKERREPOSEARCHSTRING\"" >> $AWSCONFIGFILENAME
            echo "DOCKERRREPOVERSION=$DOCKERRREPOVERSION" >> $AWSCONFIGFILENAME
            echo "JOBVCPUS=$JOBVCPUS" >> $AWSCONFIGFILENAME
            echo "JOBMEMORY=$JOBMEMORY" >> $AWSCONFIGFILENAME
            echo "NEXTFLOWCONFIGOUTPUTDIRECTORY=$NEXTFLOWCONFIGOUTPUTDIRECTORY" >> $AWSCONFIGFILENAME

    	   ./createRolesAndComputeEnv.sh $STACKNAME $COMPUTEENVIRONMENTNAME $QUEUENAME $SPOTPERCENT $MAXCPU \
                    $DEFAULTAMI $CUSTOMAMIFOREFS $EBSVOLUMESIZEGB $EFSPERFORMANCEMODE $AWSCONFIGOUTPUTDIRECTORY \
                    $AWSCONFIGFILENAME $NEXTFLOWCONFIGOUTPUTDIRECTORY $REGION $KEYNAME $S3BUCKETNAME

    	elif [ "$ARGUMENT" == "delete" ] && [ $# -eq 2 ]; then

            echo "this will take approximately three minutes"
            echo "deleting $STACKNAME  $COMPUTEENVIRONMENTNAME $QUEUENAME"
            
            source $AWSCONFIGFILENAME
            # TODO: check for running EC2 instances
            # aws ec2 describe-network-interfaces --filters Name=group-id,Values=sg-0fb51f0752d394c02,
            # research how to use query vs filter: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-network-interfaces.html
            # DESCRIPTION
            # Network interface for Bastion Node
            # EFS mount target for fs-56d23cb6 (fsmt-42d00fa3)

            #delete queue
            #echo "|------|"
            #echo -n "<."
            aws batch update-job-queue --job-queue $QUEUENAME --state DISABLED
            #JOBQUEUES   arn:aws:batch:us-east-1:725685564787:job-queue/BLJStack71Queue  BLJStack71Queue 10  DISABLED    DELETING    JobQueue Healthy
            #An error occurred (ClientException) when calling the UpdateJobQueue operation: arn:aws:batch:us-east-1:725685564787:job-queue/BLJStack71Queue does not exist
            ./sleepProgressBar.sh 5 5
            aws batch delete-job-queue --job-queue $QUEUENAME
            ./sleepProgressBar.sh 5 8
            #delete compute environment which is dependent on queue
            #An error occurred (ClientException) when calling the DeleteComputeEnvironment operation: Cannot delete, found existing JobQueue relationship
            #COMPUTEENVIRONMENTS    arn:aws:batch:us-east-1:725685564787:compute-environment/BLJStack71ComputeEnv   BLJStack71ComputeEnv    arn:aws:ecs:us-east-1:725685564787:cluster/BLJStack71ComputeEnv_Batch_3e16bbff-ca43-34b2-82d4-2042d2295664  arn:aws:iam::725685564787:role/BLJStack71-BatchServiceRole-1G661TPM7TDP0    DISABLED    VALID   ComputeEnvironment Healthy  MANAGED
            aws batch update-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME --state DISABLED
            ./sleepProgressBar.sh 5 6
            aws batch delete-compute-environment --compute-environment $COMPUTEENVIRONMENTNAME
            ./sleepProgressBar.sh 5 8
            #delete cloudformation stack

            #delete job definition
            # aws batch deregister-job-definition 
            # get a list of all jobdefs that start with $STACKNAME

            aws cloudformation delete-stack --stack-name $STACKNAME
            ./sleepProgressBar.sh 6 10

            ./awskeypair.sh delete $KEYNAME ${AWSCONFIGOUTPUTDIRECTORY}


            rm $AWSCONFIGFILENAME
            rm ${NEXTFLOWCONFIGOUTPUTDIRECTORY}config

        else
            print_help

    	fi

    else
        print_help

    fi

fi


