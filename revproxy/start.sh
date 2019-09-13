#!/bin/bash

#edit the .env file

#to join a new container to the network use:
# 1.) add the container to service definitions, docker-compose 
#  and then restart the app
# 2.) docker run ..... --network revproxy
# add the specifications to service definitions
# and re-run generate nginx config and restart nginx
# #docker restart revproxy_nginx_1
set -e

function print_help {
echo "usage: ./start.sh up"
echo "usage: ./start.sh up <mycustom.envfile>"
echo "usage: ./start.sh new"
echo "usage: ./start.sh new <mycustom.envfile>"
echo "usage: ./start.sh down"
}

if [ $# -gt 0 ];then 
#source environment file
	if [ ! -z $3 ]; then
		environment_file_path=$2
	else
		environment_file_path=.env
	fi
	source $environment_file_path

	if [ "$1" == "new" ] || [ "$1" == "up" ]; then

		if [ "$1" == "new" ]; then
			./certification_tools.sh $CERTIFICATION_METHOD
			rm "$PASSWD_FILEPATH"
		fi

		./webuser_credentials.sh adduser "$DEFAULT_USER" "$DEFAULT_PASSWORD"

		#necessary on MacOS while MacOS still uses BASH as default shell instead of ZSH
		docker run -it -v $(pwd):/app -w /app ubuntu bash -c "/app/generate_nginx_conf_file.sh"

		docker-compose up -d
	elif [ "$1" == "down" ]; then
		docker-compose down
	else
		print_help
	fi

	if [ "$VERBOSE_MODE" == "TRUE" ]; then
		docker-compose up 
	fi
else
	print_help
fi
