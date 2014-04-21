ENV['RACK_ENV'] = 'test'
require 'rubygems'
require 'bundler/setup'
require 'test_helper'
require 'minitest/autorun'
require 'rack/test'
require 'server'
require 'pp'
require 'json'


class ServerUnitTests < Minitest::Test
    include Rack::Test::Methods

    @@component = {"debug" => {:uid => "debug", :query => 'de/bug', :title => "diagnostics", :subtitle => "Debug Component", :implementation => "Debug", :spec => nil}}

    def setup()
        @session = nil
        @api = build_api(@@component.to_yaml())
    end

    def app()
        app = create_stack(@api)
        return app
    end

    def test_returns_html_for_app()
        response = get('/app.html', {})
        assert_equal(200, response.status)
        assert_match(/<html>/, response.body)
    end

    def test_returns_api_json()
        response = get('/api/', {}, 'rack.session' => @session)
        assert_equal(200, response.status)
        result = JSON.parse(response.body, :symbolize_names => true)
        refute_nil(result)
        assert_equal("menu", result[:type], "root should be a menu")
        body = result[:body]
        assert_equal(@@component.length, body.length, "one entry per component")
        expected_query = CGI.escape(@@component["debug"][:query])
        assert_equal(expected_query, body[0][:query], "web interface should escape the query parameter")
        assert_nil(body[0][:implementation], "web intrface should not expose details of implementation")
        assert_nil(body[0][:spec], "web intrface should not expose details of implementation")
    end

    def test_each_item_in_menu_returns_json()
        response = get('/api/', {}, 'rack.session' => @session)
        assert_equal(200, response.status)
        result = JSON.parse(response.body, :symbolize_names => true)
        refute_nil(result)
        assert_equal("menu", result[:type], "root should be a menu")
        action = result[:body][0][:action]
        query = result[:body][0][:query]
        response2 = get('/api/' + action + "?" + query, {}, 'rack.session' => @session)
        refute_nil(response2)
        assert_equal(200, response2.status)
        result2 = JSON.parse(response2.body, :symbolize_names => true)
        refute_nil(result2)
    end


    def test_returns_public_files()
        response = get('/winifred-mobile.css', {}, 'rack.session' => @session)
        assert_equal(200, response.status)
    end


end


