#!/bin/sh

cd /home/circleci/code-dot-org

# Changing permissions inside the docker container.
user=$(whoami)

# TODO: hopefully find a better solution than making the whole directory writeable by other users
sudo chmod -R o+w .

sudo chown $user /home/circleci/.bundle \
        apps/node_modules

# start mysql
sudo service mysql start && mysql -V

# execute original command
exec "$@"
