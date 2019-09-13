#!/bin/bash
#associative arrays:
#https://stackoverflow.com/questions/28725333/looping-over-pairs-of-values-in-bash
#must declare the service in the following four statements AND the docker-compose.yml
source .env

#note: this will not work on macOS version of bash
service_list=(webapp myotherservice myopenservice)

declare -A auth_messages=(
  [webapp]="WebApp Admin Area"
  [myotherservice]="my otherservice AdminArea"
  [myopenservice]="NONE"
)
declare -A auth_user_files=(
  [webapp]="/etc/apache2/.htpasswd"
  [myotherservice]="/etc/apache2/.htpasswd"
  [myopenservice]="NONE"
)
declare -A service_ports=(
  [webapp]="3000"
  [myotherservice]="8081"
  [myopenservice]="8080"
)

if [ "$VERBOSE_MODE" == "TRUE" ]; then
	for service_name in "${service_list[@]}"; do
	  echo "$service_name" "${auth_messages[$service_name]} ${auth_user_files[$service_name]}"
	done
fi


