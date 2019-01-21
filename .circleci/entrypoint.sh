#!/bin/sh

cd /home/circleci/code-dot-org

# Changing permissions inside the docker container.
user=$(whoami)
sudo chmod 0777 .bundle \
        locals.yml \
        dashboard/log \
        pegasus/log \
        log \
        dashboard/test/ui/log \
        dashboard/tmp \
        dashboard/config/shared_functions/GamelabJr/growing.xml

sudo chmod -R 0777 dashboard/db

sudo chown $user /home/circleci/.bundle \
        apps/node_modules

# start mysql
sudo service mysql start && mysql -V

# execute original command
exec "$@"
