require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)


class FileBrowser

    SEPS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)

    def initialize(spec, env)
        @root_dir = spec
        @batch_size = 100
    end

    attr_accessor :batch_size    #  so can test the size for testing

    def clean_path(path)
        parts = []
        parts = path.split SEPS
        clean = []
        parts.each do |part|
            next if part.empty? || part == '.'
            part == '..' ? clean.pop : clean << part
        end
        @path = File.join(*clean)
    end

    def listing(root_dir, relative_path, position)
        path = clean_path(relative_path)
        abs_path = File.join(root_dir, path)
        unless File.exists?(abs_path) and File.directory?(abs_path)
            raise RuntimeError.new("Not a directory #{abs_path}")
        end
        first = position ? Integer(position) : 0
        last = first + @batch_size - 1
        entries = Dir.entries(abs_path)[first..last]
        next_position = first + entries.length if entries and entries.length == @batch_size
        items = []
        entries && entries.each() do |entry|
            case entry
            when '.'
                # no entry for .
            when '..'
                parent = File.dirname(path)
                items << {:uid => parent, :query => parent, :action => "self", :title => '[UP]',
                          :subtitle => "Navigate to parent folder: #{parent}", :icon => "icons/arrow-back.png"}
            else
                abs_entry = File.join(abs_path, entry)
                rel_entry = File.join(path, entry)
                action = nil
                if(File.directory?(abs_entry))
                    action = "self"    # directories come back to here
                    icon = "icons/GenericFolderIcon.png"
                    count = Dir.entries(fp).size - 2  rescue 0    #  ignore . and .. and rescue if dir not accessible
                end
                icon ||= "icons/txt.png"
                size ||= File.size(abs_entry)
                time ||= File.mtime(abs_entry)
                items << {:uid => rel_entry, :query => rel_entry, :action => action, :title => entry,
                          :icon => icon, :count => count, :subtitle => "size:#{size} modified:#{time}"}
            end
        end
        return {:type => "menu", :position => next_position, :title => "Dir: #{File.basename(path)}", :body => items}
    end

    def exec(query, position = nil)
        if(query && query.length > 0)
            path = query
            return listing(@root_dir, path, position)
        else
            return listing(@root_dir, "", position)
        end
    end
end

class FileActions
    def initialize(spec, env)
        raise RuntimeError.new("rootdirectory is required") unless spec
        @root_path = spec
        #todo: allow spec to filter the available actions
        # eg email|download
    end

    def no_such_file(query)
        return {:type => "error", :status => "failed", :body => "<h2>No file found: #{path}</h2>"}
    end

    def exec(query, position = nil)

        if(query)
            full_path = File.join(@root_path, query)
        else
            full_path = @root_path
        end
        items = [{:action=> "self",   :query => "delete:#{query}", :title => "Delete", :subtitle => "Delete: #{query}", :icon => "icons/ToolbarDeleteIcon.png" },
                 {:action => "self",  :query =>"email:#{query}", :title => "Email",    :subtitle => "Email: #{query}", :icon => "icons/SentMailboxLargeTemplate@2x.png"},
                 {:href=>"/api/get",  :query => full_path,           :title => "Download", :subtitle => "Download: #{query}", :icon => "icons/ToolbarDownloadsFolderIcon.png"}]
        return {:type => "menu", :title => "File: #{query}", :body => items}
    end

end

class Tail

    def initialize(spec, env)
        @bytes = spec if spec && spec.length > 0
        @bytes ||= 1024 * 5
    end

    def no_such_file(path)
        return {:type => "error", :status => "failed", :body => "<h2>No file found: #{path}</h2>"}
    end

    def query_required()
        return {:type => "error", :status => "failed", :body => "<h2>No file specified</h2>"}
    end

    def exec(filename, position = nil)
        raise RuntimeError.new("Missing mandatory argument to Tail") unless filename
        raise RuntimeError.new("file: #{filename} could not be found") unless File.exists?(filename)
        f = File.new(filename)
        if(File.size(filename) > @bytes)
            f.seek(-1 * @bytes, IO::SEEK_END)
            f.readline()    # remove partial lines after the seek by bytes
        end
        if(position)
            f.seek(Integer(position), IO::SEEK_SET)
        end
        res = f.read(@bytes)
        body =  res
        final_position = f.pos()
        f.close()
        return {:title => filename, :position => final_position, :type => "log", :body => body}
    end

end

