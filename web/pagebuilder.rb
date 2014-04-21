require 'erb'

class PageBuilder

    def initialize(views_dir)
        @views_dir = views_dir
    end

    def include(filename)
        file_path = File.join(@views_dir, filename)
        content =  File.read(file_path)
        extension = File.extname(file_path)
        if(extension == ".erb")
            t = ERB.new(content)
            return t.result(binding())
        else
            return content
        end
    end

    def include_index()
        include("index.erb")
    end
end


def pbmain(args)
    views_dir = args[0]
    file = args[1]
    pb = PageBuilder.new(views_dir)
    puts pb.include(file)
end


if __FILE__ == $0
    pbmain(ARGV)
end
