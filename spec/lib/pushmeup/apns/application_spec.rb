require 'spec_helper'

describe Pushmeup do
  describe APNS::Application do
    let(:apns_host) { 'non-default-apns-server' }
    let(:certificate) { OpenSSL::X509::Certificate.new }
    let(:default_apns_host) { APNS::Application::DEFAULT_APNS_HOST }
    let(:device_token) { 'device token' }
    let(:message) { 'message' }
    let(:pem_contents) { 'pem contents' }
    let(:pem_location) { '/path/to/pem/apns.pem' }
    let(:pem_password) { 'pem pass' }
    let(:rsa_key) { OpenSSL::PKey::RSA.new }
    let(:ssl_socket) { double('ssl socket') }

    describe '#feedback' do
      it 'raises exception if pem is not set' do
        apns_app = APNS::Application.new
        expect { apns_app.feedback }.to raise_exception(Exceptions::PushmeupException.new(I18n.t('errors.internal.pem_is_not_set')))
      end

      context 'with no existing PEM file' do
        before(:each) do
          allow(File).to receive(:exists?).and_return(false)
        end

        it 'raises exception if pem file does not exist' do
          apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
          expect { apns_app.feedback }.to raise_exception(Exceptions::PushmeupException)
        end
      end

      context 'with existing PEM file' do
        let(:file_like_object) { double('file like object') }

        before(:each) do
          allow(File).to receive(:exists?).and_return(true)
          allow(File).to receive(:open).and_return(file_like_object)
          allow(File).to receive(:read).and_return(pem_contents)
        end

        it 'raises an exception with bad certificate' do
          apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
          expect { apns_app.feedback }.to raise_exception(OpenSSL::X509::CertificateError)
        end

        it 'raises an exception with bad key' do
          allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
          apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
          expect { apns_app.feedback }.to raise_exception(OpenSSL::PKey::RSAError)
        end

        it 'raises an ssl error' do
          allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
          allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
          apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
          expect { apns_app.feedback }.to raise_exception(OpenSSL::SSL::SSLError)
        end

        it 'sends a request to the APNS host for the notification' do
          allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
          allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
          allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(ssl_socket)
          expect(ssl_socket).to receive(:connect).and_return(true)
          allow(ssl_socket).to receive(:read)
          expect(ssl_socket).to_not receive(:write)
          expect(ssl_socket).to receive(:close).and_return(true)
          apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
          apns_app.feedback
        end
      end
    end

    describe '#initialize' do
      it 'defaults values appropriately' do
        apns_app = APNS::Application.new
        expect(apns_app.host).to eq(default_apns_host)
        expect(apns_app.pem_location).to be_nil
        expect(apns_app.pem_password).to be_nil
        expect(apns_app.port).to eq(APNS::Application::DEFAULT_APNS_PORT)
      end

      it 'sets values appropriately with initializer' do
        apns_app = APNS::Application.new(apns_host, pem_location, pem_password, 9999)
        expect(apns_app.host).to eq(apns_host)
        expect(apns_app.pem_location).to eq(pem_location)
        expect(apns_app.pem_password).to eq(pem_password)
        expect(apns_app.port).to eq(9999)
      end
    end

    describe '#send_notification' do
      context 'with persistence' do
        it 'raises exception if pem is not set' do
          apns_app = APNS::Application.new
          apns_app.start_persistence
          expect { apns_app.send_notification(device_token, message) }.to raise_exception(Exceptions::PushmeupException)
        end

        context 'with no existing PEM file' do
          before(:each) do
            allow(File).to receive(:exists?).and_return(false)
          end

          it 'raises exception if pem file does not exist' do
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            apns_app.start_persistence
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(Exceptions::PushmeupException)
          end
        end

        context 'with existing PEM file' do
          let(:file_like_object) { double('file like object') }

          before do
            allow(File).to receive(:exists?).and_return(true)
            allow(File).to receive(:open).and_return(file_like_object)
            allow(File).to receive(:read).and_return(pem_contents)
          end

          it 'raises an exception with bad certificate' do
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            apns_app.start_persistence
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(OpenSSL::X509::CertificateError)
          end

          it 'raises an exception with a bad key' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            apns_app.start_persistence
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(OpenSSL::PKey::RSAError)
          end

          it 'raises an ssl error' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
            allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            apns_app.start_persistence
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(OpenSSL::SSL::SSLError)
          end

          it 'sends a request to the APNS host for the notification' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
            allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
            allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(ssl_socket)
            expect(ssl_socket).to receive(:connect).and_return(true)
            expect(ssl_socket).to receive(:write).and_return(true)
            expect(ssl_socket).to_not receive(:close)
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            apns_app.start_persistence
            apns_app.send_notification(device_token, message)
          end
        end
      end

      context 'without persistence' do
        it 'raises exception if pem is not set' do
          apns_app = APNS::Application.new
          expect { apns_app.send_notification(device_token, message) }.to raise_exception(Exceptions::PushmeupException)
        end

        context 'with no existing PEM file' do
          before(:each) do
            allow(File).to receive(:exists?).and_return(false)
          end

          it 'raises exception if pem file does not exist' do
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(Exceptions::PushmeupException)
          end
        end

        context 'with existing PEM file' do
          let(:file_like_object) { double('file like object') }

          before do
            allow(File).to receive(:exists?).and_return(true)
            allow(File).to receive(:open).and_return(file_like_object)
            allow(File).to receive(:read).and_return(pem_contents)
          end

          it 'raises an exception with bad certificate' do
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(OpenSSL::X509::CertificateError)
          end

          it 'raises an exception with a bad key' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(OpenSSL::PKey::RSAError)
          end

          it 'raises an ssl error' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
            allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            expect { apns_app.send_notification(device_token, message) }.to raise_exception(OpenSSL::SSL::SSLError)
          end

          it 'sends a request to the APNS host for the notification' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
            allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
            allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(ssl_socket)
            expect(ssl_socket).to receive(:connect).and_return(true)
            expect(ssl_socket).to receive(:write).and_return(true)
            expect(ssl_socket).to receive(:close).and_return(true)
            apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
            apns_app.send_notification(device_token, message)
          end
        end
      end
    end

    describe '#send_notifications' do
      let(:file_like_object) { double('file like object') }

      before do
        allow(File).to receive(:exists?).and_return(true)
        allow(File).to receive(:open).and_return(file_like_object)
        allow(File).to receive(:read).and_return(pem_contents)
      end

      it 'allows you to send multiple notifications' do
        allow(OpenSSL::X509::Certificate).to receive(:new).and_return(certificate)
        allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)
        allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(ssl_socket)
        expect(ssl_socket).to receive(:connect).once.and_return(true)
        expect(ssl_socket).to receive(:write).twice.and_return(true)
        expect(ssl_socket).to receive(:close).once.and_return(true)
        apns_app = APNS::Application.new(default_apns_host, pem_location, pem_password)
        notification1 = APNS::Notification.new(device_token, message)
        notification2 = APNS::Notification.new(device_token, message)
        apns_app.send_notifications([notification1, notification2])
      end
    end

    describe '#start_persistence' do
      it 'sets @persistent to true' do
        apns_app = APNS::Application.new
        expect(apns_app.persistent).to be_falsey
        apns_app.start_persistence
        expect(apns_app.persistent).to be_truthy
      end
    end

    describe '#stop_persistence' do
      it 'sets @persistent to false and closes connections' do
        apns_app = APNS::Application.new
        expect(apns_app.persistent).to be_falsey
        apns_app.start_persistence
        expect(apns_app.persistent).to be_truthy
        apns_app.stop_persistence
        expect(apns_app.persistent).to be_falsey
      end
    end
  end
end