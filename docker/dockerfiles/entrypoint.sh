#!/bin/sh

cd /home/circleci/code-dot-org

# Run https://github.com/boxboat/fixuid allow writes to bind-mounted code-dot-org directory
eval $( fixuid )

# start mysql
sudo service mysql start && mysql -V

# execute original command
exec "$@"
