#!/bin/bash


#This auto-mounts your scratch volume to /docker_scratch, 
#which is your scratch directory for batch processing. The 
#last two commands stop the ECS agent and remove any persistent data checkpoint files.
# Next, create your new AMI and record the image ID.

sudo yum -y update
dockerstoragesize=$(docker info | grep -i base)
echo "Docker storage size equals: $dockerstoragesize"
sudo parted /dev/xvdb mklabel gpt
sudo parted /dev/xvdb mkpart primary 0% 100%
sudo mkfs -t ext4 /dev/xvdb1
sudo mkdir /docker_scratch
sudo echo -e '/dev/xvdb1\t/docker_scratch\text4\tdefaults\t0\t0' | sudo tee -a /etc/fstab
sudo mount -a


#conda install instructions from nextflow
#conda install -c conda-forge -y awscli
sudo yum install -y wget
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -f -p $HOME/miniconda
$HOME/miniconda/bin/conda install -c conda-forge -y awscli
rm Miniconda3-latest-Linux-x86_64.sh

./miniconda/bin/aws --version


sudo stop ecs
sudo rm -rf /var/lib/ecs/data/ecs_agent_data.json

