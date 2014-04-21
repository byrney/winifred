require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require_relative 'files'
require_relative 'scripts'
require_relative 'debug'
require_relative 'application'
require_relative 'process'


class OpenUrl

    def initialize(spec, env)
        @template = "{query}"
        @template = spec if spec && spec.length > 0
    end

    def exec(query, position = nil)
        url = @template.gsub("{query}", query)
        return {:type => 'url', :body => url}
    end

end


