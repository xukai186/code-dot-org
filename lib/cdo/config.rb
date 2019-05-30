require 'singleton'
require 'cdo/yaml'
require 'active_support/core_ext/hash/reverse_merge'

module Cdo
  ####################################################################################################
  ##
  ## Config - A singleton that loads and combines application configuration settings.
  ##
  ## Config priority (highest to lowest):
  ##
  ## ENV             - environment variables (CDO_*)
  ## locals.yml      - Local configuration
  ## globals.yml     - [Chef-]provisioned configuration
  ## config[env]     - environment-specific defaults
  ## config[default] - global defaults
  ##
  ##########
  class Config < OpenStruct
    include Singleton

    def initialize
      super
      self.env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      load_configuration
      load_secrets
      raise "'#{rack_env}' is not known environment." unless rack_envs.include?(rack_env)
      ENV['RACK_ENV'] ||= env.to_s
      @table.each_key(&method(:new_ostruct_member!))
      @initialized = true
    end

    def method_missing(*args)
      raise NoMethodError if @initialized
      super
    end

    def load_configuration
      root = File.expand_path('../../..', __FILE__)
      # 1. ENV - environment variables (CDO_*)
      cdo_env = ENV.to_h.select {|k, _| k.start_with?('CDO_')}.transform_keys {|k| k.delete_prefix('CDO_').downcase}
      # 2. locals.yml - local configuration
      locals = YAML.load_file(File.join(root, 'locals.yml')) || {}
      # 3. globals.yml - [Chef-]provisioned configuration
      globals = YAML.load_file(File.join(root, 'globals.yml')) || {}
      merge cdo_env, locals, globals

      config = YAML.load_erb_file(File.join(root, 'config.yml.erb'), binding)
      # 4. config[env] - environment-specific defaults
      config_env = config[env]
      # 5. config[default] - global defaults
      config_default = config['default']
      merge config_env, config_default
    end

    def merge(*configs)
      configs.each do |config|
        config.transform_keys!(&:to_sym)
        process_secrets(config)
        table.reverse_merge!(config)
      end
    end

    # Stores a reference to a Secret so it can be resolved later.
    class Secret
      attr_reader :key
      def initialize(key)
        @key = key
      end
    end

    def process_secrets(config)
      secrets = (config.delete(:secrets) || []).product([env])
      shared_secrets = (config.delete(:shared_secrets) || []).product(['shared'])
      (secrets + shared_secrets).each do |key, prefix|
        config[key] ||= Secret.new("#{prefix}/cdo/#{key}")
      end
    end

    def load_secrets
      table.select {|_k, v| v.is_a?(Secret)}.each do |key, secret|
        require 'cdo/secrets'
        self.cdo_secrets ||= Cdo::Secrets.new
        self[key] = cdo_secrets.lazy(secret.key)
      end
    end
  end
end
