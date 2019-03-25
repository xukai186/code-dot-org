module Cdo
  # Lazy-loads a delegated object from a block.
  #
  # Example:
  #
  # > lazy = Cdo.lazy {puts 'loaded!'; 'Lazy'}; true
  # => true
  # > puts lazy
  # loaded!
  # Lazy
  # => nil
  class Lazy < SimpleDelegator
    def initialize(&block)
      @block = block
    end

    def __getobj__
      __setobj__(@block.call) unless defined?(@delegate_sd_obj)
      super
    end
  end

  def self.lazy(&block)
    Lazy.new(&block)
  end
end
