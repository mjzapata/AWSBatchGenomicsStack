

## edit the .env file

## start.sh new
## start.sh up

# ./webuser_credentials.sh

## to join a new container to the network use:
# 1.) add the container to service definitions, docker-compose 
  and then restart the app
# 2.) docker run ..... --network revproxy
 add the specifications to service definitions
 and re-run generate nginx config and restart nginx
 #docker restart revproxy_nginx_1