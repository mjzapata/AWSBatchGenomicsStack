#!/bin/bash

#TODO: mount properties and behavior
# https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-general.html

efsID=$1

efs_directory=/mnt/efs

sudo mkdir /mnt/efs
sudo chown -R ec2-user:ec2-user /mnt/efs

#sudo sed -i 's/^.*Required-Start.*$/# Required-Start: \$network cgconfig nfs netfs/' /etc/init.d/docker
sudo sed -i 's/^.*Required-Start.*$/# Required-Start: \$ALL/' /etc/init.d/docker

echo "${efsID}:/ ${efs_directory} efs tls,_netdev" | sudo tee --append /etc/fstab


#sudo mount -t efs ${efsID}:/ /mnt/efs


df -T
echo "verify EFS appended to fstab"

sudo stop ecs
sudo rm -rf /var/lib/ecs/data/ecs_agent_data.json
