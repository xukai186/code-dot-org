require 'singleton'
require 'cdo/yaml'

module Cdo
  # Loads and combines structured application configuration settings.
  class Config < OpenStruct
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

    # Loads one or several sources into the merged configuration.
    # Resolves dynamic config self-references by re-rendering + merging until result is unchanged.
    def load_configuration(*sources)
      config = nil
      i = 5
      table = @table
      while config != (config = render(*sources))
        raise "Can't resolve config (circular dependency?)" if (i -= 1).zero?
        @table = table.dup
        config.each(&method(:merge))
      end
    end

    # Renders config source into a hash, loading ERB/YAML files based on extension.
    def render(*sources)
      sources.map do |source|
        if source.is_a?(Hash)
          source
        elsif File.extname(source) == '.yml'
          YAML.load_file(source) || {}
        elsif File.extname(source) == '.erb'
          YAML.load_erb_file(source, binding) || {}
        end
      end
    end

    # Merge the provided config hash into the current config.
    # 'Reverse-merge' keeps existing values except for `nil`.
    def merge(config)
      return if config.nil?
      table.merge!(config.transform_keys(&:to_sym)) do |_key, old, new|
        old.nil? ? new : old
      end
    end
  end
end
