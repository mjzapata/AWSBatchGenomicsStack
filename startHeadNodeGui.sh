#!/bin/bash
#docker pull amyerke/webapp

#move to docker service later so it can be restarted with the computer

#docker run -it --rm -p 8080:3000     -v /var/run/docker.sock:/var/run/docker.sock      -v $BLJ/resources/config/gui:/config     -v $BLJ/web_app/logs:/app/biolockj/web_app/logs    -v $BLJ_PROJ:/pipeline:delegated     -e "HOST_BLJ_PROJ=$BLJ_PROJ"     -e "HOST_BLJ=$BLJ"     -e "BLJ_SUP=$BLJ_SUP"     --entrypoint=/bin/bash amyerke/webapp
EXTERNALPORT=8080
publichostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
HOSTADDRESS="http://${publichostname}:${EXTERNALPORT}"
DOCKERIMAGE=amyerke/webapp

#instead do:
#https://medium.freecodecamp.org/dockers-detached-mode-for-beginners-c53095193ee9
 # docker start 
 # docker exec 
 #this should override existing running commands in the same container?  if name the container properly

#detached
#docker run -p $HOSTADDRESS:3000 -e HOST_ENVIRONMENT='AWS' -v ~/.batchawsdeploy/:/root/.batchawsdeploy -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=/bin/bash $DOCKERIMAGE

docker run -d -p ${EXTERNALPORT}:3000 \
	-e HOST_ENVIRONMENT='AWS' \
	-v ~/.batchawsdeploy/:/root/.batchawsdeploy \
	-v /var/run/docker.sock:/var/run/docker.sock  \
	$DOCKERIMAGE

echo ""
echo "****************************************************************"
echo "****************************************************************"
echo HOSTADDRESS=$HOSTADDRESS
echo "Head Node Gui available at:   
	 ${HOSTADDRESS}"
echo "****************************************************************"
echo "****************************************************************"


#NOTE: CANNOT RUN IT HERE!!!
#ERROR ABOUT STDIN NOT BEING A TTY

