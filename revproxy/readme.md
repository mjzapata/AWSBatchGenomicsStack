

# 1.) edit the .env file
### change the default password or a randomly generated password will be used and printed to the terminal:
```DEFAULT_USER=biolockjuser
DEFAULT_PASSWORD=changeme```

### decide whether the domain name is local-host or determined by the AWS DNS servers (AWSDEFINED)

### Enable VERBOSE_MODE=TRUE if needed for troubleshooting.

# 2.) First time setup
### ./start.sh new   
### (or ./start.sh up)

### ./start.sh new runs the following:
### ./certification_tools.sh $CERTIFICATION_METHOD
### ./webuser_credentials.sh adduser "$DEFAULT_USER" "$WEBPASS"  (creates the )
### docker-compose up -d  (or docker-compose up if VERBOSE_MODE=TRUE)

# to join a new container to the network use:
### 1.) add the container to service definitions in docker-compose.yml
### with the following values:
### networks:
###      - frontend
###    expose:
###      - 3000
###    env_file:
###      - ./container_variables.env
###    environment:
###      - VIRTUAL_HOST=webapp.${COMMON_NAME}
###      - VIRTUAL_PORT=3000
# 2.) docker run ..... --network revproxy_frontend  <myimagename>
 add the specifications to service definitions
 and re-run generate nginx config and restart nginx
 #docker restart revproxy_nginx_1

 ### echo 'auth_basic_user_file '"${passwd_container_filepath}"';' >> ${NGINX_CONF_FILE_PATH}
 location /files {
    auth_basic off;
}