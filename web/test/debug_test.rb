require 'test_helper'
require 'debug'

class DebugTest < MiniTest::Unit::TestCase
    def test_can_create()
        dbg = Debug.new(nil, nil)
        refute_nil(dbg)
    end

    def test_ignores_unknown_params()
        dbg = Debug.new(nil, nil)
        result = dbg.exec("unknown_parameter", nil)
        assert_nil(result)
    end

    def test_no_params_returns_menu()
        dbg = Debug.new(nil, nil)
        result = dbg.exec({}, nil)
        assert_equal("menu", result[:type])
    end

    def test_each_menu_item_returns_results()
        expected_env = {"item1" => "value1"}
        dbg = Debug.new(nil, expected_env)
        result = dbg.exec({}, nil)
        assert_equal("menu", result[:type])
        items = result[:body]
        args = items.collect {|x| x[:query] }
        args.each {|a| assert_equal("html", dbg.exec(a)[:type]) }
    end
end


