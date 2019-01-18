FROM amyerke/webapp:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y \
 python-dev \
 python-pip \
 python-tk 

# install AWS CLI
RUN pip install awscli --upgrade
RUN aws --version

#ENV NXF_OPTS='-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap' NXF_HOME=/.nextflow

# download nextflow runtime and move it to /usr/local/bin
#RUN wget -qO- https://get.nextflow.io | bash && mv nextflow /usr/local/bin
#RUN mkdir /.nextflow
#RUN chmod 755 /usr/local/bin/nextflow \
# && nextflow info

# define the entry point TODO: what does the official nextflow docker say about entrypoint?
#ENTRYPOINT ["/usr/local/bin/entry.sh"]
ENTRYPOINT ["/bin/bash"]


