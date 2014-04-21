require 'test_helper'
require 'minirack'

class MinimalRackUnitTests < Minitest::Test
    include Rack::Test::Methods

    @@names = ["debug", "browse", "actions"]
    @@component0 = {:uid => "debug", :inputs => :optional, :query => 'debug', :title => "diagnostics",
                    :subtitle => "Debug Component", :default_action => "self", :implementation => "Debug", :spec => nil}
    @@component1 = {:uid => "browse", :inputs => :optional, :title => "Files", :default_action => @@names[1],
                    :subtitle => "File Component", :implementation => "FileBrowser", :spec => Dir.getwd()}
    @@component2 = {:uid => "requires_inputs", :inputs => :required, :title => "FileActions",
                    :subtitle => "File Component", :implementation => "FileActions", :spec => nil}
    def setup()
        @session = nil
    end

    def app()
        api = MiniRack.new
        api.component_add(@@names[0], @@component0)
        api.component_add(@@names[1], @@component1)
        api.component_add(@@names[2], @@component2)
        return api
    end

    def test_returns_component_list_for_root()
        result = call_and_parse('/')
        assert_equal("menu", result[:type])
        items = result[:body]
        assert_equal(2, items.length)
        assert_equal(@@component0[:title], items.first[:title])
        assert_equal(@@component1[:title], items[1][:title])
        assert_equal(nil, items.index { |i| i[:title] == @@component2[:title]} , "Items with required inputs do not appear in top level")
    end

    def call_and_parse(uri, headers = nil)
        headers = {}
        response = get(uri, headers, 'rack.session' => @session)
        assert_equal(200, response.status)
        result = JSON.parse(response.body, :symbolize_names => true)
        return result
    end

    def test_selfaction_goes_back_to_same_component()
        result = call_and_parse('/debug')
        refute_nil(result)
        assert_equal(@@names[0], result[:body].first[:action], "action of self means use same component")

    end

    def test_noaction_goes_to_default_for_component()
        result = call_and_parse('/browse')
        refute_nil(result)
        result[:body].each {|i| assert_includes(@@names, i[:action], "action for browse is either self or file") }
    end

    def test_debug_returns_failure_when_unknown_params_passed()
        result = call_and_parse('/debug?query=someparams')
        assert_equal("error", result[:type])
    end

    def test_debug_returns_json_menu_when_no_params()
        result = call_and_parse('/debug')
        refute_nil(result, "result should be parsable json")
        assert_equal("menu", result[:type])
    end

    def test_file_returns_json_menu_when_no_params()
        result = call_and_parse('/browse')
        refute_nil(result, "result should be parsable json")
        assert_equal("menu", result[:type])
    end

    def test_debug_returns_json_params()
        result = call_and_parse('/debug?query=env')
        refute_nil(result, "result should be parsable json")
        refute_nil(result[:type])
        refute_nil(result[:status])
        refute_nil(result[:body])
    end

    def test_call_to_unknown_uses_cookie()
        response = get('/debug?query=param', {}, 'rack.session' => rack_mock_session)
        response2 = get('/NO_CONTEXT', {}, 'rack.session' => rack_mock_session)
        assert_equal(response.body, response2.body)

    end

    def test_get_returns_file()
        this_file = File.expand_path(__FILE__)
        url = '/get?query=' + CGI.escape(this_file)
        response = get(url, {})
        expected_headers = {"Content-Type"=>"text/x-script.ruby"}
        expected_headers.each {|k,v| assert_equal(v, response.header[k]) }
    end
end


