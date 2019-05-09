#/bin/bash
set -e

service mysql start
service nginx start
service varnish start
service pegasus start
service dashboard start

# TODO: should check for health of services: https://docs.docker.com/config/containers/multi-service_container/
tail -f /dev/null

