FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y
        curl \
        vim

EXPORT CHEF_VERSION=12.7.2

RUN curl -L https://omnitruck.chef.io/install.sh | bash -s -- -v ${CHEF_VERSION}