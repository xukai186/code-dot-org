add_formatter :doc, '/var/log/chef-bootstrap-debug.log'
log_level :info
node_name 'adhoc-chef-docker-build'
environment 'adhoc'
chef_repo_path '/var/chef'
local_mode true

