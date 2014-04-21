#!/usr/bin/ruby
require 'pp'


class ProcessList

    def initialize(spec, env)
        @spec = spec
    end

    def exec(query, position)
        query ||= ""
        filter = /#{query}/
        pscmd = "ps -e -o 'pid,#{@spec},command' "
        ps = %x( #{pscmd} )
        line = 0
        processes = []
        titles = nil
        ps.each_line do |row|
            row.chomp!()
            if(line == 0)
                titles = row.split(' ')
            else
                a = row.split(' ', titles.length)
                deets = {}
                titles.each_index {|i| deets[titles[i]] = a[i] }
                pid = deets["PID"]
                cmd = deets.delete("COMMAND")
                next unless filter.match(cmd)
                subtitle = ""
                deets.each_pair {|k,v| subtitle << k + ": " + v + " "}
                processes << {:uid => pid, :title => cmd, :subtitle => subtitle, :query => pid, :icon => "icons/process.png"}
            end
            line += 1
        end
        return {:type => "menu", :body => processes}
    end

end

class ProcessActions
    def initialize(spec, env)
        @signals = ["KILL"]
        @signals = spec.split("|") if spec && spec.length
    end

    def exec(query, position)
        raise RuntimeError.new("Query is required for Process Actions") unless query
        pid,sig = query.split(':')
        if(sig)
            res =  Process.kill(sig,Integer(pid))
            msg = res == 0 ? "Failed" : "OK"
            return {:type => "html", :status => msg, :body => "<h1>Send #{sig} to #{pid}:</h1><h2>#{msg}</h2>" }
        else
            items = []
            @signals.each do |s|
                items << {:uid => "x", :title => s, :action => "self", :query => "#{pid}:#{s}", :icon => "icons/process.png"}
            end
            return {:type => "menu", :body => items }
        end
    end
end


def main()

    spec="uid,ppid,pid,stime"
    p = ProcessList.new(spec, nil)
    res = p.exec(ARGV[0])
    pp res
    return 0

end


if $0 == __FILE__
    main()
end
