#!/usr/bin/env bash

set -xe

docker run --name cdo-unit-tests --env-file docker_tests/env.list -v /home/circleci wjordan/code-dot-org:0.5 '/bin/sh -c "cd /home/circleci; env;"'
docker rm cdo-unit-tests