// 1.a) Stage Data:
//params.in = "$baseDir/data/multiplexed/combinedFastq/combined.fastq.gz"
//sequences = file(params.in)
// 1.b) What if data is already in S3?
params.efsdir = "/efs/"
params.projectname = "testproj1"
params.projectdir = "${params.efsdir}${params.projectname}/"

num = Channel.from( 1, 2, 3, 4)


process Createprojectdir {
  echo true //enable forward stdout 
  label 'image_mjzapata2_ubuntu_latest'
  label 'DEMAND'
  cpus 2
  memory '4 GB'

  output:
  val true into create_complete_ch

  """
  #!/bin/bash
  echo "LS /efs/ before mkdir projectdir:"
  ls -al ${params.efsdir}
  echo ""

  mkdir ${params.projectdir}

  echo "LS /efs/ after mkdir projectdir:"
  touch ${params.projectdir}test1
  ls -al ${params.efsdir}
  """
}

process Gunzip {
	echo true
  label 'image_mjzapata2_ubuntu_latest'
  label 'DEMAND'
  cpus 2
  memory '4 GB'
  
  input:
  val x from num
  val flag from create_complete_ch

  output:
  val true into gunzip_complete_ch

	"""
	#!/bin/bash
	echo "LS /efs/PROJECTDIR in GunZip"
	ls -al ${params.projectdir}

  # 1.) Download zip file
  #wget -O ${params.projectdir}test_${x}.zip http://ipv4.download.thinkbroadband.com/200MB.zip 

  # test write speed
  # https://askubuntu.com/questions/87035/how-to-check-hard-disk-performance 
  # but need to output dd to stdout instead of stderr:
  # https://askubuntu.com/questions/625224/how-to-redirect-stderr-to-a-file
  echo "testing write speed for EFS volume using dd:"
  #time sh -c "dd if=/dev/zero of=${params.projectdir}testfile bs=1000k count=1k && sync"
  sync ; time sh -c "dd if=/dev/zero of=${params.projectdir}testfile_${x}.zip bs=1000k count=1k 2>&1 && sync"
  echo "wrote file: ${params.projectdir}testfile_${x}.zip"
  #echo "sleep 10 to keep node busy so batch jobs cant request the same node.  Just for testing"
  #sleep 10
  #echo "done sleeping!"
	"""
}

process echoGunzip {
  echo true
  label 'image_mjzapata2_ubuntu_latest'
  label 'DEMAND'
  cpus 2
  memory '4 GB'

  input:
  file worker from Channel.watchPath( "${params.projectdir}*.zip" )

  output:
  val true into echogunzip_complete_ch

  """
  #!/bin/bash
  echo "process echoGunzip"
  echo ${worker}

  """
}

process listFilesAndDeleteProjectdir {
  echo true
  label 'image_mjzapata2_ubuntu_latest'
  label 'DEMAND'
  cpus 4
  memory '6 GB'

  input:
  val flag from gunzip_complete_ch.collect()

  """
  #!/bin/bash

  # 2.) LS of projectdir
  ls -al ${params.projectdir}

  #3.) remove contents of EFS to save money
  rm -rf ${params.projectdir}*
  echo ""
  echo "LS /efs AFTER wipe"
  ls -al ${params.projectdir}

  """
}
