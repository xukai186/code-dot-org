#
# Cookbook Name:: cdo-cloudwatch-logger
# Recipe:: default
#

# Compiled from https://github.com/zendesk/cloudwatch-logger release v1.
ark 'cloudwatch-logger' do
  url 'https://cdo-dist.s3.amazonaws.com/cloudwatch-logger.tar.gz'
  has_binaries ['cloudwatch-logger']
end

fifo = '/var/log/cloudwatch'
cloudwatch_logger = '/usr/local/bin/cloudwatch-logger.sh'

file 'cloudwatch-logger' do
  path cloudwatch_logger
  content <<SH
#!/bin/bash
mkfifo #{fifo}
chown syslog: #{fifo}
(while true ; do cat #{fifo} ; done) | cloudwatch-logger -t #{node.environment}-syslog "$(hostname)-$$"
SH
  mode '0755'
end

poise_service 'cloudwatch-logger' do
  command cloudwatch_logger

  environment AWS_REGION: node[:ec2][:region]
  subscribes :restart, 'file[cloudwatch-logger]', :delayed
  subscribes :restart, 'ark[cloudwatch-logger]', :delayed
end

file '99-cdo.conf' do
  path "/etc/rsyslog.d/#{name}"
  content <<FILE
Module (path="builtin:ompipe")
*.* action(type="ompipe" Pipe="#{fifo}")
FILE
end

service 'rsyslog' do
  subscribes :restart, 'template[99-cdo.conf]', :delayed
end
