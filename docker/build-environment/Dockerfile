FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y \
        ruby-bundler \
        ruby2.5-dev \
        build-essential \
        libffi-dev \
# Docker installation prequisites https://docs.docker.com/install/linux/docker-ce/ubuntu/
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common \
# Needed to install AWS CLI
        python3-pip

# Install Docker https://docs.docker.com/install/linux/docker-ce/ubuntu/
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
RUN apt-get update && \
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io

# Install AWS CLI
RUN pip3 install awscli
