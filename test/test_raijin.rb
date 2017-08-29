gem 'test-unit'
require 'test/unit'
require 'raijin'

class TestRaijin < Test::Unit::TestCase
  sub_test_case 'default private methods' do
    setup do
      @cli = Class.new(Raijin).new
    end

    test '#command_nothing' do
      assert_raise(Raijin::Error){ @cli.__send__ :command_nothing }
    end
  end
end
