require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'webrick/https'

class RegisterApp

    def call(env)
        request = Rack::Request.new(env)
        response = Rack::Response.new()
        puts "Called Register app: #{request.request_method}"
        case request.request_method
        when 'GET'
            env['PATH_INFO'] = 'keygen.html'
            return Rack::File.new('public').call(env)
        when 'POST'
            #request.params.each_key { |k| puts k + " = " + request.params[k] }
            pubkey = request.params['pubkey']
            username = request.params['username']
            cert = File.read(generate_certificate(pubkey, username))
            [200, {'Content-Type' => 'application/x-x509-user-cert' }, [cert]]
        else
            [404, {}, ["No such method"]]
        end
    end

    def generate_certificate(pubkey, username)
        spkac = "SPKAC=#{pubkey}\nCN=#{username}@winifred.app\nemailAddress=robert@byrnemail.org\n0.OU=Winifred Client Certificate"
        spkac += "\norganizationName=Robert Byrne\ncountryName=GB\nstateOrProvinceName=London\n"
        puts spkac
        tempfile = Tempfile.new("clientcerts")
        tempname = tempfile.path
        tempfile.write(spkac)
        tempfile.close()
        outname = tempname + ".signed"
        system("cd ssl && openssl ca -config /System/Library/OpenSSL/openssl.cnf -days 180 -spkac #{tempname} -out #{outname} -notext -passin pass:'90318rb' ")
        return outname
    end

end

def create_stack()
    stack = Rack::Builder.new() do
        map '/' do
            run RegisterApp.new
        end
    end
    return stack
end

if $0 == __FILE__
    cert_name = [ %w[CN localhost], ]
    port = 7890
    server_certificate = OpenSSL::X509::Certificate.new( File.open("security/server/localhost-chain.pem").read)
    private_key = OpenSSL::PKey::RSA.new( File.open("security/server/localhost-key-np.pem").read)
    Rack::Server.start(:app => create_stack(), :environment => :development, :Port => port,
                       :SSLEnable => true,
                       :SSLPrivateKey => private_key,
                       :SSLCertificate => server_certificate,
                       :SSLCACertificateFile => 'ssl/demoCA/cacert.pem',
                       :SSLCertName => cert_name)
end

