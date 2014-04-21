
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class Debug
    def initialize(spec, env)
        @env = env
    end

    def env_to_html(env)
        response = "<table>"
        env.each{ |k,v| response += "<tr><td>#{k}</td><td>#{v}</td></tr>" }
        response += "</table>"
    end

    def exec(query, position = nil)
        result = nil
        if(query && query.length >0)
            if(query == "env")
               result = {:status => "ok", :type => "html", :title => "Headers", :body => env_to_html(@env)}
            end
            if(query == "param")
               result = {:status => "ok", :type => "html", :title => "Parameters", :body => "<h2>Parameters</h2><p>" + query.to_s + "</p>"}
            end
            return result
        else
            items = []
            items << {:action => "debug", :query => "env", :title => "Env", :subtitle => "Print the rack environment"}
            items << {:action => "debug", :query => "param", :title => "Parameters", :subtitle => "Print the parameters passed"}
            return {:type => "menu", :title => "Diagnostics", :body => items}
        end
    end
end
