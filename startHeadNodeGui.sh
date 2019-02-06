#!/bin/bash


docker run --name webapp -it --rm -v /var/run/docker.sock:/var/run/docker.sock --entrypoint "/bin/bash" amyerke/webapp

