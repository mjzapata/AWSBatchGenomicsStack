#!/bin/bash

ec2-35-173-236-109.compute-1.amazonaws.com

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



conf_file_path=data/nginx/app.conf
cert_path=/etc/letsencrypt/live/
host_name=
cert_suffix=.crt
key_suffix=.key

echo "server {
    listen 80;
    server_name ${hostname};
    location / {
        return 301 https://\$host\$request_uri;
    }
    location /.well-known/acme-challenge/ {
    root /var/www/certbot;
    }
}
server {
    listen 443 ssl;
    server_name ${hostname};
    location / {
        proxy_pass http://${hostname};
    }
    ssl_certificate ${cert_path}${hostname}${cert_suffix};
    ssl_certificate_key ${cert_path}${hostname}${key_suffix};
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}" > $conf_file_path



upstream docker-webapp {
        server webapp:3000;
}
upstream docker-loginsrv {
        server loginsrv:8080;
}

server {
    listen 80;
    server_name ec2-35-173-236-109.compute-1.amazonaws.com;
    location / {
        return 301 https://$host$request_uri;
    }
}
server {
    listen 443 ssl;
    server_name ec2-35-173-236-109.compute-1.amazonaws.com;

    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;

    location /login {
        proxy_pass http://docker-loginsrv;
    }
    location / {
        proxy_pass http://docker-webapp;
    }
    ssl_certificate /etc/nginx/conf.d/ec2-35-173-236-109.compute-1.amazonaws.com.crt;
    ssl_certificate_key /etc/nginx/conf.d/ec2-35-173-236-109.compute-1.amazonaws.com.key;
}
