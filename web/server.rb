require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'pagebuilder'
require 'json'
require 'components'
require 'minirack'
require 'webrick/https'
require 'openssl'

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
    return true
    #system("dscl", ".", "-authonly", username, password)
end

def build_api(components_yaml)
    api = MiniRack.new(components_yaml)
    return api
end

class ClientCertAuth

    def initialize(application)
        puts "CLientCertAuth:init"
        @app = application
    end

    def call(env)
        client_cert_raw = env['SSL_CLIENT_CERT']
        client_cert = OpenSSL::X509::Certificate.new(client_cert_raw)
        store = OpenSSL::X509::Store.new
        cacert = OpenSSL::X509::Certificate.new(File.read("security/ca/winifred-ca-cert.pem"))
        store.add_cert(cacert)
        if( store.verify(client_cert) )
            puts "Certificate login by #{client_cert.subject}"
            return @app.call(env)
        else
            return [403, {}, ["Client certificate failed to verify"]]
        end
    end
end

def create_stack(api)
    stack = Rack::Builder.new() do
        env = ENV['RACK_ENV']
        use ClientCertAuth unless env == 'test'
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

def start_thin_ssl()

    options = {:environment => :development, :port => port, :address => '0.0.0.0',
               :ssl => true, :ssl_key_file => 'ssl/localhost-key.pem', :ssl_cert_file => 'ssl/localhost-chain.pem',
               :ssl_verify => true, :log => 'logs.txt'}
    thin = Thin::Server.new('0.0.0.0', 8433, options, create_stack(api))
    thin.ssl = true
    thin.ssl_options = { :private_key_file => options[:ssl_key_file], :cert_chain_file => options[:ssl_cert_file],
                         :verify_peer => options[:ssl_verify] }
    pp thin
    thin.start
end

if $0 == __FILE__
    cert_name = [ %w[CN localhost], ]
    config = File.read("workflows.yaml")
    api = build_api(config)
    puts api.dump()
    port = 8444
    #Rack::Handler::WEBrick.run(create_stack(api), :Port => 8443, :SSLEnable => false, :SSLCertName => cert_name)
    $0 = "winifred -port #{port}"

    #    Thin::Server.start('0.0.0.0', 8433, create_stack(api), options)
    server_certificate = OpenSSL::X509::Certificate.new( File.open("security/server/laura-chain.pem").read)
    private_key = OpenSSL::PKey::RSA.new( File.open("security/server/laura-key-np.pem").read)
    Rack::Server.start(:app => create_stack(api), :environment => :development, :Port => port,
                       :SSLEnable => true,
                       :SSLVerifyClient => OpenSSL::SSL::VERIFY_PEER|OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
                       :SSLPrivateKey => private_key,
                       :SSLCertificate => server_certificate,
                       :SSLCACertificateFile => 'security/ca/winifred-ca-cert.pem',
                       :SSLCertName => cert_name,
                      )
end


