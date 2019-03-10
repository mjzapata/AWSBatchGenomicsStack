#!/bin/bash
#docker pull amyerke/webapp

#move to docker service later so it can be restarted with the computer

#docker run -it --rm -p 8080:3000     -v /var/run/docker.sock:/var/run/docker.sock      -v $BLJ/resources/config/gui:/config     -v $BLJ/web_app/logs:/app/biolockj/web_app/logs    -v $BLJ_PROJ:/pipeline:delegated     -e "HOST_BLJ_PROJ=$BLJ_PROJ"     -e "HOST_BLJ=$BLJ"     -e "BLJ_SUP=$BLJ_SUP"     --entrypoint=/bin/bash amyerke/webapp
EXTERNALPORT=8080
docker run -p $EXTERNALPORT:3000 -v ~/.batchawsdeploy/:/root/.batchawsdeploy -v /var/run/docker.sock:/var/run/docker.sock amyerke/webapp

echo "available at "


#NOTE: CANNOT RUN IT HERE!!!
#ERROR ABOUT STDIN NOT BEING A TTY

