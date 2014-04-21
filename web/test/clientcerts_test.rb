require 'test_helper'
require 'openssl'
require 'clientcerts'


class ClientCertsUnitTests < Minitest::Test
    def setup()
        @@ca_cert_file = "citest-ca-cert.pem"
        @@ca_key_file = "citest-ca-key.pem"
        cert = read_test_fixture(@@ca_cert_file)
        key = read_test_fixture(@@ca_key_file)
        @subject = ClientCerts.new(cert, key)
        @serial = 1
        @ca_cert = OpenSSL::X509::Certificate.new(cert)
        @username = "citestuser"
        @@export_pass = "4321"
    end

    def test_can_create_subject()
        refute_nil(@subject)
    end

    def test_create_keypair()
        keypair = @subject.create_keypair()
        refute_nil(keypair)
        refute_nil(keypair.public_key)
        assert_equal(true, keypair.private?)
    end

    def test_create_certificate()
        keypair = @subject.create_keypair()
        pubkey = keypair.public_key()
        cert = @subject.create_certificate(@username, pubkey, @serial)
        refute_nil(cert)
        cert_subject = cert.subject
        refute_nil(cert_subject)
        subject_hash = cert_subject.to_a.inject({}) { |memo, i| memo[i[0]] = i[1] ; memo }
        assert_equal(@username, subject_hash["CN"])
        assert_equal(2, cert.version)
        assert_equal(cert.issuer.to_a, @ca_cert.subject.to_a)
        verified = OpenSSL::SSL.verify_certificate_identity(cert,@username)
        assert(verified)
        pubkey = cert.public_key
        refute_nil(pubkey)
    end

    def test_sign()
        keypair = @subject.create_keypair()
        pubkey = keypair.public_key()
        cert = @subject.create_certificate(@username, pubkey, @serial)
        signed_cert = @subject.sign_certificate(cert)
        verify_cert(signed_cert)
    end

    def verify_cert(cert)
        store = OpenSSL::X509::Store.new
        store.add_cert @ca_cert
        verified = store.verify(cert)
        assert(verified)
    end

    def test_pkcs12()
        keypair = @subject.create_keypair()
        pubkey = keypair.public_key()

        cert = @subject.create_certificate(@username, pubkey, @serial)
        signed_cert = @subject.sign_certificate(cert)
        pkcs = @subject.create_pkcs12(@@export_pass, @username, keypair, signed_cert)
        refute_nil(pkcs)
        #assert_equal(@username, pkcs.
        File.open("citest.p12", "wb") { |f| f.write(pkcs.to_der) }
    end


end


