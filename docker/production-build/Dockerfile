FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y \
        curl \
        vim

ENV CHEF_VERSION=12.7.2
ENV CHEF_BOOTSTRAP_DIR=/etc/chef
ENV CHEF_REPO_DIR=/var/chef

RUN curl -L https://omnitruck.chef.io/install.sh | bash -s -- -v ${CHEF_VERSION}

RUN mkdir -p ${CHEF_BOOTSTRAP_DIR} && mkdir -p ${CHEF_REPO_DIR}/environments

COPY docker/production-build/first-boot.json ${CHEF_BOOTSTRAP_DIR}
COPY docker/production-build/client.rb ${CHEF_BOOTSTRAP_DIR}
COPY docker/production-build/adhoc.json ${CHEF_REPO_DIR}/environments

# add ubuntu user
RUN groupadd --gid 1000 ubuntu \
  && useradd --uid 1000 --gid ubuntu --create-home ubuntu \
  && echo 'ubuntu ALL=NOPASSWD: ALL' >> /etc/sudoers.d/ubuntu

USER ubuntu
RUN mkdir /home/ubuntu/adhoc
COPY --chown=ubuntu:ubuntu . /home/ubuntu/adhoc

USER root
RUN cp -r /home/ubuntu/adhoc/berks-package.tar.gz /var/chef && \
    cd /var/chef && \
    tar -xzf berks-package.tar.gz
