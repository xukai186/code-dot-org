require 'singleton'

module Cdo
  ####################################################################################################
  ##
  ## Config - A singleton that contains global application configuration settings.
  ##
  ## Config priority (highest to lowest):
  ##
  ## ENV             - environment variables
  ## locals.yml      - Local configuration
  ## globals.yml     - [Chef-]provisioned configuration
  ## config[env]     - environment-specific defaults
  ## config[default] - global defaults
  ##
  ##########
  class Config < OpenStruct
    include Singleton

    def load_configuration
      root_dir = File.expand_path('../../..', __FILE__)

      # Combine secret lists when merging configuration hashes.
      secrets = ->(key, a, b) {%i[secrets shared_secrets].include?(key) ? a | b : b}

      global_config = YAML.load_file(File.join(root_dir, 'globals.yml')) || {}
      local_config = YAML.load_file(File.join(root_dir, 'locals.yml')) || {}
      config = global_config.merge(local_config, &secrets)

      env = config['env'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      ENV['RACK_ENV'] ||= env.to_s
      rack_env = env.to_sym

      # ERB-process config file.
      default_file = File.join(root_dir, 'config.yml.erb')
      default_yaml = ERB.new(File.read(default_file), nil, '-').tap {|erb| erb.filename = default_file}.result(binding)
      default = YAML.load(default_yaml, default_file)

      config = [default['default'], default[env], config].inject {|old, new| old.merge(new, &secrets)}

      config['rack_env'] = config['rack_env'].to_sym
      config['rack_envs'] = config['rack_envs'].map(&:to_sym)
      raise "'#{rack_env}' is not known environment." unless config['rack_envs'].include?(rack_env)
      config
    end

    def initialize
      @table = {}
      super load_configuration
    end
  end
end
