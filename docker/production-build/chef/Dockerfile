FROM pre-chef-client

USER ubuntu

RUN export USER=ubuntu && \
    sudo /opt/chef/bin/chef-client -c /etc/chef/client.rb -j /etc/chef/first-boot.json

COPY entrypoint.sh /entrypoint.sh

USER root
CMD /entrypoint.sh
