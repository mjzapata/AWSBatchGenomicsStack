params.in = "$baseDir/data/multiplexed/combinedFastq/combined.fastq.gz"
sequences = file(params.in)

QUEUENAME='BLJQueue36'
params.projectname = "testproj1"
params.efsdir = "/efs/"
params.projectdir = "${params.efsdir}${params.projectname}/"

process gunzip {
	queue '$QUEUENAME'
	container 'job-definition://testJob3BLJStack36-ECSTaskRole-16K53ZUTXGDTP:1'
  	echo true //forward stdout (delete to suppress stdout)
  	input:
  	file 'combined.fastq.gz' from sequences
  	"""
  	#!/bin/bash

  	# 0.) Make projectdir 
    mkdir ${params.projectdir}
    # 1.) LS contents of EFS
  	echo "LS /efs BEFORE wipe"
  	ls -al ${params.efsdir}
  	
  	# 2.) unzip staged file
  	echo ""
  	echo "UNZIP:"
  	gunzip --uncompress --stdout --quiet --to-stdout combined.fastq.gz > ${params.projectdir}combined3.fastq
  	# 2.a) LS of projectdir
    ls -al ${params.projectdir}

    #3.) remove contents of EFS to save money
    rm -rf ${params.efsdir}*
    echo ""
    echo "LS /efs AFTER wipe"
  	ls -al ${params.efsdir}


  	"""
}
