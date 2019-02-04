FROM biolockj/manager:latest

ARG DEBIAN_FRONTEND=noninteractive

#2.) ======== Basic pre-reqs for most ubuntu systems =================== #
RUN apt-get update && \
	apt-get install -y build-essential \
	checkinstall \
	apt-utils \
	software-properties-common \
	git \
	unzip \
	ca-certificates \
	bsdtar \
	wget \
	nano \
	curl

#4.) =================    Java   ======================== #  
# Add the appropriate repository, and autoselect menu options to avoid user interaction during install.
RUN apt-get update && \
   apt-get upgrade -y && \
   apt-get install -y  software-properties-common && \
   add-apt-repository ppa:webupd8team/java -y && \
   apt-get update && \
   echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
   apt-get install -y oracle-java8-installer && \
   apt-get clean


#5.) =================   Python  ======================== #  
#Python2.7, pip
#add python legacy releases
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y \
 python2.7 \
 python-dev \
 python-pip \
 python-tk 

# AWS CLI
RUN pip install awscli --upgrade
# see https://blogs.oracle.com/java-platform-group/java-se-support-for-docker-cpu-and-memory-limits
ENV NXF_OPTS='-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap' NXF_HOME=/.nextflow

# download nextflow runtime
RUN curl -s https://get.nextflow.io | bash && mv nextflow /usr/local/bin
RUN mkdir /.nextflow
RUN chmod 755 /usr/local/bin/nextflow \
 && nextflow info


# define the entry point TODO: what does the official nextflow docker say about entrypoint?
#ENTRYPOINT ["/usr/local/bin/entry.sh"]
ENTRYPOINT ["/bin/bash"]


