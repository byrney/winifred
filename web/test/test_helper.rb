require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/reporters'
require 'pp'
require 'json'
require 'rack/test'

ENV['RACK_ENV'] = 'test'
if ENV["RM_INFO"] || ENV["TEAMCITY_VERSION"]
	puts("TEAMCITY_VERSION=" + ENV["TEAMCITY_VERSION"]);
	MiniTest::Reporters.use! MiniTest::Reporters::RubyMineReporter.new
else
    MiniTest::Reporters.use! if RUBY_PLATFORM =~ /darwin/
end

