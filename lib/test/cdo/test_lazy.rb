require_relative '../test_helper'
require 'cdo/lazy'

class LazyTest < Minitest::Test
  def test_lazy
    loaded = false
    lazy = Cdo.lazy {loaded = true; 'Lazy'}
    refute loaded
    assert_equal 'Lazy', lazy
    assert loaded
  end
end
