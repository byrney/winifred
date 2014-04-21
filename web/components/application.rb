require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class ApplicationControl
    def initialize(spec, env)
        @process_name = spec
    end

    def isRunning(name)
        %x(killAll -SIGINFO #{name})
        return $?.exitstatus == 0
    end

    def exec(query, position = nil)
        if(query == nil || query.size == 0)
            # generate a menu of actions that can be performed
            items = []
            if(isRunning(@process_name))
                items << {:title => "Stop", :subtitle => "Stop: #{@process_name}", :action => "self", :icon => "icons/application_delete.png", :query => "stop"}
                items << {:title => "Restart", :subtitle => "Restart: #{@process_name}", :action => "self", :icon => "icons/application_double.png", :query => "restart"}
            else
                items << {:title => "Start", :subtitle => "Start: #{@process_name}", :action => "self", :icon => "icons/application_add.png", :query => "start"}
            end
            return {:title => @process_name, :type => "menu", :body => items}
        else
            case query
            when 'start'
                res  = start(@process_name)
            when 'stop'
                res  = stop(@process_name)
            when 'restart'
                stop(@process_name)
                res  = start(@process_name)
            else
                return exec(nil, nil)
            end
            msg = ( res == 0 ) ? "Success" : "Failed: #{res}"
            return {:title => @process_name, :type=>"html", :body => "<h2>#{@process_name} #{query}</h2><p>#{msg}</p>"}
        end
    end

    def start(name)
        %x(open -g -a #{name})
        return $?.exitstatus
    end

    def stop(name)
        %x(killAll #{name})
        return $?.exitstatus
    end

end

