#!/bin/bash
argument=$1
user_name=$2
password=$3


if [ ! -z $4 ]; then
	environment_file_path=$4
else
	environment_file_path=.env
fi
source $environment_file_path

minimum_password_length=8
function print_help {
echo "Note: this script uses relative paths to write to data/auth/.htpasswd so must
be run from the directory containing the script"
echo "usage: ./webuser_credentials.sh --help"
echo "usage: ./webuser_credentials.sh adduser <myusername>"
echo "usage: ./webuser_credentials.sh adduser <myusername> <mypassword>"
echo "usage: ./webuser_credentials.sh adduser <myusername> <mypassword> <mycustom .env file>"
echo "usage: ./webuser_credentials.sh deleteuser <myusername>"
echo "ERROR: $1"
echo ""
}
#htpasswd reference: https://httpd.apache.org/docs/2.4/programs/htpasswd.html
if [ "$#" -ge 1 ] && [ "$#" -le 4 ]; then

	if [[ "$argument" != *"-h"* ]]; then  #if -h is in arg1, bring up help 
		#ADDUSER
		if [ "$argument" == "adduser" ]; then
			if [ "$#" -ge 2 ] && [ "$#" -le 4 ]; then #verify correct number of arguments
				htpasswd_opts=m #use m5 encryption (MUST have at least one option specified here)
				if [ ! -f "$PASSWD_FILEPATH" ]; then htpasswd_opts="${htpasswd_opts}c"; fi 	  #-c for create .htpasswd
				if [ ! -z "$password" ]; then htpasswd_opts="${htpasswd_opts}b"; fi 	  #-b for batch mode
				if [ ! -z  "$htpasswd_opts" ]; then htpasswd_opts="-${htpasswd_opts}"; fi #add dash in front
				if [[ "$VERBOSE_MODE" == "TRUE"  ]]; then echo "VERBOSE: htpasswd_opts=$htpasswd_opts"; fi  #VERBOSE

				if [ -z "$password" ]; then # if no password supplied, prompt user
					htpasswd "$htpasswd_opts" "$PASSWD_FILEPATH" "$user_name" 
				elif [ ${#password} -ge $minimum_password_length ]; then  #test password length
					htpasswd "$htpasswd_opts" "$PASSWD_FILEPATH" "$user_name" "$password"
				else
					print_help "passwords must be at least $minimum_password_length characters. password_length=${#password}"
				fi
			else
				print_help "incorrect number of arguments for adduser"
			fi
			#DELETEUSER
		elif [ "$argument" != "deletuser" ]; then
			if [ "$#" -ge 2 ]; then
				htpasswd_opts=-D
				if [[ "$VERBOSE_MODE" == "TRUE"  ]]; then echo "VERBOSE: htpasswd_opts=$htpasswd_opts"; fi  #VERBOSE
				htpasswd "$htpasswd_opts" "$PASSWD_FILEPATH" "$user_name"  #DELETEUSER
			else
				print_help "incorrect number of arguments for deleteuser"
			fi
		else
			print_help "must specify adduser, deleteuser"
		fi
	else
		print_help "specified $argument option to print help"
	fi
else
 	print_help "expected 2 or 3 arguments, received $#"
fi


