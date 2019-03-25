module Cdo
  # Custom YAML tag +!Secret+ indicates a Secret value to be fetched later.
  # Contains an optional +value+ specifying a Secret ID.
  # If +value+ is nil, the parent key will be used as the ID.
  class Secret
    attr_reader :value

    def initialize(value)
      @value = value
    end

    # Resolve YAML::Secret tags in provided config hash to lazy-loaded secrets.
    def self.resolve!(hash, secrets)
      hash.to_h.select {|_, v| v.is_a?(self)}.each do |k, v|
        # If value is nil, use parent key as ID.
        value = v.value || k
        fallback = nil
        value, fallback = value if value.is_a?(Array)
        hash[k] = secrets.lazy(value, fetch: false, fallback: fallback)
      end
      hash
    end
  end

  ::YAML.add_domain_type('', 'Secret') {|_, value| Secret.new(value)}
end
