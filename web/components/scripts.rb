
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'open3'

class ScriptAction
    def initialize(spec, env)
        @interp = spec[:interpreter]
        @script = spec[:script]
    end

    def exec(query, position = nil)
        command = @script
        command += %( ") + query + %(") if query
        output,proc_status = Open3.capture2(@interp, :stdin_data => command)
        return process_script_output(query, output, proc_status.success?())
    end

    def process_script_output(query, output, success)
        status = success ? "ok" : "failed"
        return {:type => "html", :status => status, :body => "<pre>#{output}</pre>"}
    end

end

class ScriptFileAction < ScriptAction

    def exec(query, position = nil)
        arg =  query ? query : ""
        tempfile = Tempfile.new('scriptaction')
        tempname = tempfile.path
        #raise ArgumentError.new("Unable to locate script file #{@script}") unless File.exists?(@script)
        spawn(@interp, @script, arg, :out => tempname)
        # return a menu with the option to view the logfile
        item = {:title => "View Logfile", :subtitle =>tempname, :action => "tail", :query => File.expand_path(tempfile.path)}
        return {:type => "menu", :body => [item]}
    end

end

require 'rexml/document'

class ScriptFilter < ScriptAction

    def process_script_output(query, output, success)
        doc = REXML::Document.new(output)
        raise RuntimeError.new("return from script filter doesn't look like valid xml") unless doc.root
        items = []
        doc.elements.each('/items/item') do |e|
            title = e.elements["title"].text
            subtitle = e.elements["subtitle"].text
            icon = e.elements["icon"].text
            arg = e.attributes["arg"]
            href = e.attributes["href"]
            action = e.attributes["action"]
            items << {:title => title, :action => action, :href => href, :subtitle => subtitle, :icon => icon, :query => arg}
        end
        return {:type => "menu", :body => items}
    end

end

