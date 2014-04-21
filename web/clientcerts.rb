require 'openssl'
require 'pp'

class ClientCert
    def initialize(username, public_key, ca_cert, serial)
        #@cert =
    end
end
class ClientCerts

    def initialize(ca_cert_string, ca_key_string)
        @@seconds_per_year = 365 * 24 * 60 * 60
        @ca_cert = OpenSSL::X509::Certificate.new(ca_cert_string)
        @ca_key = OpenSSL::PKey::RSA.new(ca_key_string, "1234")
        @cert = nil
    end

    def create_keypair()
        OpenSSL::PKey::RSA.new(1024)
    end

    def create_certificate(username, public_key, serial)
        cert = OpenSSL::X509::Certificate.new()
        cert.version = 2
        cert.serial = serial
        cert.subject = OpenSSL::X509::Name.parse( "/DC=CITEST/CN=#{username}" )
        cert.issuer = @ca_cert.subject
        cert.public_key = public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + 1 * @@seconds_per_year
        return cert
    end

    def sign_certificate(cert)
        cert.sign(@ca_key, OpenSSL::Digest::SHA256.new)
        return cert
    end

    def create_pkcs12( export_pass, username, keys, signed_cert )
        OpenSSL::PKCS12.create(export_pass, username, keys, signed_cert)
    end

    def save_cert( username, cert )
    end


end
