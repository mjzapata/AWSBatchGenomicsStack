#!/bin/bash

function print_help {
echo "usage: ./generate_nginx_conf_file.sh"
echo "usage: ./generate_nginx_conf_file.sh <mycustom.envfile>"
}
#     ec2-35-173-236-109.compute-1.amazonaws.com

if [ ! -z $1 ]; then
	environment_file_path=$2
else
	environment_file_path=.env
fi
source $environment_file_path

#instead do:
#https://medium.freecodecamp.org/dockers-detached-mode-for-beginners-c53095193ee9
 # docker start 
 # docker exec 
 #this should override existing running commands in the same container?  if name the container properly

#detached
#docker run -p $HOSTADDRESS:3000 -e HOST_ENVIRONMENT='AWS' -v ~/.batchawsdeploy/:/root/.batchawsdeploy -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=/bin/bash $DOCKERIMAGE



conf_file_path=${NGINX_CONF_FILE_PATH}
cert_path=${container_cert_directory}

if [ "$COMMONNAME" == "AWSDEFINED" ]; then	
	publichostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
	COMMONNAME="$publichostname"
fi


#if exists, ask if you want to overwrite (maybe)
echo " " > $conf_file_path

echo "server {
    listen 80;
    server_name ${COMMONNAME};
    location / {
        return 301 https://\$host\$request_uri;
    }
}" >> $conf_file_path

echo "server {
    listen 443 ssl;
    server_name ${COMMONNAME};
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_redirect off;" >> $conf_file_path


#for each service...
source service_definitions.sh

for service_name in "${service_list[@]}"; do

	echo "location /${service_name}/ {" >> $conf_file_path

	if [ "${auth_user_files[$service_name]}" != "NONE" ]; then
		echo -e "\t auth_basic \"${auth_messages[$service_name]}\";" >> $conf_file_path
    	echo -e "\t auth_basic_user_file ${auth_user_files[$service_name]};" >> $conf_file_path
	fi
	echo -e "\t proxy_pass http://${service_name}:${service_ports[$service_name]}/;" >> $conf_file_path
	echo -e "\t}" >> $conf_file_path
done

echo "
    ssl_certificate ${cert_path}${COMMONNAME}.${cert_suffix};
    ssl_certificate_key ${cert_path}${COMMONNAME}.${key_suffix};
}
" >> $conf_file_path

