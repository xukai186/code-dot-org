require 'active_support/cache'
require 'active_support/notifications'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/hash/reverse_merge'

# cache_method module refinement.
# Memoizes function in the provided cache store.
#
# @example
# class MyClass
#   using CacheMethod
#   cached def echo(x)
#     puts "Processing #{x}..."
#     x
#   end
# end
#
# > MyClass.new.echo 'foo'
# Processing foo...
# => "foo"
# > MyClass.new.echo 'foo'
# => "foo"
# > MyClass.new.echo 'bar'
# Processing bar...
# => "bar"
#
module CacheMethod
  DEFAULT_CACHE_OPTIONS = {
    cache: ActiveSupport::Cache::MemoryStore.new,
    expires_in: 1.minute
  }.freeze

  mattr_accessor(:cache_options) {Hash.new({})}

  refine Module do
    def cache_options
      CacheMethod.cache_options[self]
    end

    def cache_options=(options)
      CacheMethod.cache_options[self] = options
    end

    def cached(method_id, options=cache_options)
      options.reverse_merge! DEFAULT_CACHE_OPTIONS
      cache = options.delete(:cache)
      version = options.delete(:version)
      original_method_id = "_cache_method_#{method_id}"
      alias_method original_method_id, method_id
      define_method method_id do |*args, &blk|
        cache_key = ActiveSupport::Cache.expand_cache_key([method(method_id).inspect, args], version)
        cache.fetch(cache_key, options) do
          send(original_method_id, *args, &blk)
        end
      end
    end
  end
end
