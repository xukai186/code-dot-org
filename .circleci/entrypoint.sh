#!/bin/sh

cd /home/circleci/code-dot-org

# Changing permissions inside the docker container.
user=$(whoami)
sudo chmod o+w .bundle \
        locals.yml \
        dashboard/log \
        pegasus/log \
	pegasus \
        log \
        dashboard/test/ui/log \
        dashboard/tmp

sudo chmod -R o+w dashboard/db \
	dashboard/config/shared_functions

sudo chown $user /home/circleci/.bundle \
        apps/node_modules

# start mysql
sudo service mysql start && mysql -V

# execute original command
exec "$@"
