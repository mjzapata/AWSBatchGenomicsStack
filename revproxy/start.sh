#!/bin/bash

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

		if [ "$DEFAULT_PASSWORD" == "changeme" ]; then
			WEBPASS=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
			echo "**************************************************"
			echo -e "no default password set in file \".env\"  Using password: $WEBPASS"
			echo "**************************************************"
			echo ""
		else
			WEBPASS="$DEFAULT_PASSWORD"
		fi

		./webuser_credentials.sh adduser "$DEFAULT_USER" "$WEBPASS"

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
