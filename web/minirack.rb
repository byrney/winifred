require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'pagebuilder'
require 'json'
require 'components'
require 'yaml'
require 'pry'

class MiniRack

    def initialize(components_yaml = nil)
        @components = {}
        @components = YAML.load(components_yaml) if components_yaml
        @getter = Rack::File.new('/')
        @@top_level_inputs = [:none, :optional]
    end

    attr_accessor :components

    def dump()
        @components.to_yaml()
    end

    def component_list()
        items = []
        @components.each_pair do |key, value|
            query_provided = value[:query] && value[:query].length >0
            top_level = @@top_level_inputs.include?(value[:inputs])
            if( top_level || query_provided )
                arg = value[:query] ? CGI.escape(value[:query]) : ""
                items << {:action => key, :query => arg, :title => value[:title], :subtitle => value[:subtitle], :icon => value[:icon]}
            end
        end
        result = {:type => "menu", :body => items, :title=>"Actions"}
        return result
    end

    def component_exception(e, action_name, query)
        body =  "<h1>Error invoking component</h1><h3>Action: #{action_name}</h3><h3>Query: #{query}</h3><h3>#{e.message}</h3><pre>#{e.backtrace.inspect}</pre>"
        return {:type => "error", :body =>body}
    end

    def system_exception(params, path, e)
        {:type => "html", :body => "<h1>System Error</h1><h3>Params: #{params}</h3><h3>Path: #{path}</h3><h3>#{e.message}</h3><pre>#{e.backtrace.inspect}</pre>"}
    end

    def call(env)
        path = env["PATH_INFO"]
        request = Rack::Request.new(env)
        params = request.params
        query = params["query"] && CGI.unescape(params["query"])
        position = params["position"] && CGI.unescape(params["position"])
        return process(path, query, position, request, env)
    rescue Exception => e
        puts "SYSTEM ERROR: " + e.message + "\n" + e.backtrace.inspect
        return [200, {}, [system_exception(params, path, e).to_json]]
    end

    def process(path, query, position, request, env)
        case path
        when "/"
            return [200, {}, [component_list().to_json()]]
        when "/get"
            env["PATH_INFO"] = query
            return @getter.call(env)
        when "/NO_CONTEXT"
            cookie_query = request.cookies()["DexContext"]
            path,query = cookie_query.split('&',2)
            return self.process(path, query, nil, request, env)
        else
            result = dispatch(path, query, position, env)
            return [404, {}, ["Not found: path"]] unless result
        end
        headers = {}
        Rack::Utils.set_cookie_header!(headers, "DexContext", {:value => [path, query], :path => "/"})
        return [200, headers, [result.to_json()]]
    end

    def dispatch(path, query, position, env)
        comp_name = path[1..-1]
        component = @components[comp_name]
        raise ArgumentError.new("Unknown action: #{comp_name}") unless component
        check_component_args(comp_name, component, query, position)
        result = invoke_component(component, query, position, env, comp_name)
        return post_process_result!(result, component, comp_name)
    end

    def invoke_component(component, query, position, env, comp_name)
        instance = Kernel.const_get(component[:implementation]).new(component[:spec], env)
        result = instance.exec(query, position)
        raise RuntimeError.new("Component returned nil result") unless result
        return result
    rescue Exception => e
        return component_exception(e,comp_name, query)
    end

    def check_component_args(comp_name, component, query, position)
        has_query = query && query.length > 0
        case component[:inputs]
        when :required
            raise RuntimeError.new("Component #{comp_name} requires arguments but was passed none") unless has_query
        when :none
            raise RuntimeError.new("Component #{comp_name} does not accept arguments") if has_query
        end
    end

    def post_process_result!(result, component, comp_name)
        if(result[:type] == "menu")
            items = result[:body]
            items.each do |v|
                v[:query] = CGI.escape(v[:query]) if v[:query]                               #  args get escaped for url
                v[:action] = component[:default_action] if v[:action] == nil            # use component default action if none set
                v[:action] = comp_name if v[:action] == "self"                          #  self means use the same component
            end
        end
        result[:position] = CGI.escape(result[:position].to_s) if result[:position]
        result[:title] ||= component[:title]
        return result
    end

    def component_add(name, config)
        components[name] = config
    end

    def component_remove(name)
        components.delete(name)
    end
end

