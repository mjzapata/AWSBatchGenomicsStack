

# 1.) edit the .env file
1.a)change the default password or a randomly generated password will be used and printed to the terminal:
```
DEFAULT_USER=biolockjuser
DEFAULT_PASSWORD=changeme
```

1.b) decide whether the domain name is local-host or determined by the AWS DNS servers (AWSDEFINED)
	-Specify the location of certification and organization name
```
CERTIFICATION_METHOD=self-signed
COUNTRY="US"
STATE="North Carolina"
LOCATION="Charlotte"
ORGANIZATION="BioLockJ"
```
1.c) Decide if the hostname is localhost, or if it is determined by AWS
	-if COMMONNAME=AWS_DEFINED then the EC2 instance will ping AWS services for its hostname
```
#COMMON_NAME=AWSDEFINED
#COMMON_NAME=MYCUSTOMDOMAIN
COMMON_NAME=localhost
```
1.d) Enable VERBOSE_MODE=TRUE if needed for troubleshooting.
```
VERBOSE_MODE=FALSE
```

# 2.) First time setup
```
./start.sh new   
(or ./start.sh up)
```
./start.sh new runs the following:
```
./certification_tools.sh $CERTIFICATION_METHOD
./webuser_credentials.sh adduser "$DEFAULT_USER" "$WEBPASS"  (creates the )
docker-compose up -d  (or docker-compose up if VERBOSE_MODE=TRUE)
```

# to join a new container to the network use:
## 2.a) add the container to service definitions in docker-compose.yml
with the following values:
```
networks:
     - frontend
   expose:
     - 3000
   env_file:
     - ./container_variables.env
   environment:
     - VIRTUAL_HOST=webapp.${COMMON_NAME}
     - VIRTUAL_PORT=3000
```
## 2.b) OR run a docker run command like this:
```
docker run --network revproxy_frontend --env-file ./container_variables.env --env VIRTUAL_HOST=myappname.${COMMON_NAME} --env VIRTUAL_PORT <myportnumber> <myimagename>
```



