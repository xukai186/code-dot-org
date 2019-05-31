require 'singleton'
require 'cdo/yaml'
require 'cdo/lazy'

module Cdo
  ####################################################################################################
  #
  # Config - A singleton that loads and combines application configuration settings.
  #
  # Config priority (highest to lowest):
  #
  # 1. ENV             - environment variables (CDO_*)
  # 2. locals.yml      - Local configuration
  # 3. globals.yml     - [Chef-]provisioned configuration
  # 4. config[env]     - environment-specific defaults
  # 5. config[default] - global defaults
  #
  ##########
  class Config < OpenStruct
    include Singleton

    def initialize
      super
      load_configuration
      lazy_load_secrets!
      raise "'#{rack_env}' is not known environment." unless rack_envs.include?(rack_env)
      freeze
    end

    # Soft-freeze: Don't allow any new config members to be created,
    # but allow setting existing items to new values.
    def freeze
      @table.each_key(&method(:new_ostruct_member!))
      @initialized = true
    end

    def method_missing(key, *args)
      raise ArgumentError, "Undefined #{self.class} reference: #{key}", caller(1) if @initialized
      super
    end

    # Match CDO_*, plus RACK_ENV and RAILS_ENV.
    ENV_PREFIX = /^(CDO|(RACK|RAILS)(?=_ENV))_/

    def load_configuration
      root = File.expand_path('../../..', __FILE__)
      merge(
        # 1. ENV - environment variables (CDO_*)
        ENV.to_h.select {|k, _| k.match?(ENV_PREFIX)}.transform_keys {|k| k.sub(ENV_PREFIX, '').downcase},
        # 2. locals.yml - local configuration
        YAML.load_file(File.join(root, 'locals.yml')) || {},
        # 3. globals.yml - [Chef-]provisioned configuration
        YAML.load_file(File.join(root, 'globals.yml')) || {}
      )
      ENV['RACK_ENV'] = self.env ||= 'development'

      # To resolve ERB config self-references, re-render / merge ERB until result is unchanged.
      config = nil
      i = 5
      table = @table
      while config != (config = YAML.load_erb_file(File.join(root, 'config.yml.erb'), binding))
        raise "Can't resolve config.yml.erb (circular dependency?)" if (i -= 1).zero?
        @table = table.dup
        merge(
          # 4. config[env] - environment-specific defaults
          config[env],
          # 5. config[default] - global defaults
          config['default']
        )
      end
    end

    # Merges the provided config hashes into the current config.
    def merge(*configs)
      configs.each do |config|
        config = config.transform_keys(&:to_sym)
        process_secrets!(config)
        # Reverse-merge: Keep existing values except nil.
        table.merge!(config) {|_key, old, new| old.nil? ? new : old}
      end
    end

    # Stores a reference to a secret so it can be resolved later.
    class Secret
      attr_reader :key
      def initialize(key)
        @key = key
      end
    end

    # Converts items in :secrets / :shared_secrets arrays to `Secret` references in the provided config hash.
    # To disable all secrets processing set the config key to `false`, e.g.: `shared_secrets: false`.
    def process_secrets!(config)
      {secrets: env, shared_secrets: 'shared'}.each do |secret_key, prefix|
        secrets_keys = config[secret_key]
        next unless secrets_keys.is_a? Array
        config.delete(secret_key)
        secrets_keys.each do |key|
          unless config.key?(key)
            config[key] = (@table[secret_key] === false) ? nil :
              Secret.new("#{prefix}/cdo/#{key}")
          end
        end
      end
    end

    # Resolve secret references to lazy-loaded values.
    def lazy_load_secrets!
      self.cdo_secrets = nil
      table.select {|_k, v| v.is_a?(Secret)}.each do |key, secret|
        require 'cdo/secrets'
        cdo_secrets = self.cdo_secrets ||= Cdo::Secrets.new
        table[key] = cdo_secrets.lazy(secret.key)
        define_singleton_method(key) do
          # Replace lazy references to the underlying object on first access,
          # in order to support 'falsey' (false / nil) values.
          val = @table[key]
          val = @table[key] = val.__getobj__ if val.is_a?(Cdo::Lazy)
          val
        end
      end
    end
  end
end
