require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'pagebuilder'
require 'json'
require 'components'
require 'minirack'
require 'webrick/https'

class MobileApp
    def self.call(env)
        path = env["PATH_INFO"]
        return [404, {}, "Not found: #{path}"] unless path== ''
        response = Rack::Response.new()
        pb = PageBuilder.new("views")
        response.write(pb.include("layout.erb"))
        response.status = 200
        response.finish()
    end
end

def authenticate(username, password)
    system("dscl", ".", "-authonly", username, password)
end

def build_api(components_yaml)

    api = MiniRack.new(components_yaml)
    # api.component_add("debug", :inputs => :optional, :uid => "debug", :arg => '', :implementation => "Debug", :spec => nil,
    #                   :title => "Diagnostics", :subtitle => "Debug Component", :icon => 'icons/UtilitiesFolder.png')
    # api.component_add("browse", :uid => "browse", :inputs => :optional, :arg => '', :default_action => "file", :implementation => "FileBrowser", :spec => Dir.home,
    #                   :title => "Home", :icon => 'icons/user-home.png', :subtitle => "Browse home directory (#{Dir.home})")
    # api.component_add("file", :uid => "file", :arg => '', :inputs => :required, :implementation => "FileActions", :spec => Dir.getwd(),
    #                   :title => "Files", :subtitle => "File Component" )
    # api.component_add("awsmenu", :uid => "aws", :arg => '', :default_action => 'awsopen', :inputs => :optional, :implementation => "ScriptFilter",
    #                   :spec => {:interpreter => '/bin/bash', :script => '$HOME/Documents/Alfred2/Alfred.alfredpreferences/workflows/user.workflow.649D603E-4AC3-4559-84AE-6B040EF1A214/xmlfilter.sh'},
    #                   :icon => 'icons/aws.png', :title => "Amazon Console", :subtitle => "Open Amazon AWS Console" )
    # api.component_add("awsopen", :uid => "awsopen", :arg => '', :inputs => :required, :implementation => "OpenUrl",
    #                   :spec => {:template => "https://console.aws.amazon.com/{query}/home"},
    #                   :title => "Amazon Console URL", :subtitle => "Open Amazon AWS URL" )
    # api.component_add("iTunesApp", :uid => "iTunesApp", :inputs => :optional, :implementation => "ApplicationControl", :spec => {:process_name => "iTunes"},
    #                   :title => "iTunes Application Control", :subtitle => "Start/Stop iTunes.app", :icon => "icons/iTunes.png")
    # api.component_add("periodic", :uid => "periodic", :arg => '-f',  :inputs => :none, :implementation => "ScriptFileAction",
    #                   :spec => {:interpreter => '/bin/bash', :script => '/Users/rob/.periodic'},
    #                   :title => "Periodic Jobs", :subtitle => "Force run periodic", :icon => "icons/Awaken.png" )
    # api.component_add("periodiclog", :uid => "periodiclog", :arg => '/Users/rob/Library/Logs/periodic.log', :inputs => :none, :implementation => "Tail",
    #                   :title => "Periodic Logs", :subtitle => "tail periodic logs", :icon => "icons/Schedule_File.png" )
    # api.component_add("tail", :uid => "tail", :inputs => :require, :implementation => "Tail",
    #                   :title => "Tail", :subtitle => "tail", :icon => "icons/Schedule_File.png" )

    return api
end

def create_stack(api)

    stack = Rack::Builder.new() do
        env = ENV['RACK_ENV']
        if(env != 'test')
            use Rack::Auth::Basic do |username, password|
                authenticate(username, password)
            end
        end
        map '/api' do
            run api
        end
        map '/app.html' do
            run MobileApp
        end
        run Rack::File.new('public')
    end

    return stack
end

if $0 == __FILE__
    cert_name = [ %w[CN localhost], ]
    config = File.read("workflows.yaml")
    api = build_api(config)
    puts api.dump()
    Rack::Handler::WEBrick.run(create_stack(api), :Port => 8443, :SSLEnable => false, :SSLCertName => cert_name)
    #Rack::Server.start(:app => create_stack(), :environment => :development)
end


