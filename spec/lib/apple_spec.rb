require 'spec_helper'
require 'rspec'

describe Pushmeup do
  describe "APNSv3" do
    it "should have a GCM object" do
      defined?(APNSV3).should_not be_false
    end

    context "Notification creation" do
      context "when the notification can be successfully created" do
        notification = APNSV3::Notification.new("id", "some message")
        notification.class.should == (APNSV3::Notification)
      end

      context "when the notification creation fails" do
        it "message should not be anything than a Hash or a String" do
          expect {APNSV3::Notification.new("id", 2)}.to raise_error Exception
        end
      end
    end

    context "Request creation" do
      context "when the request can be successfully created" do
        it 'create successful request' do
          SecureRandom.stub(uuid: 'some_uuid')
          notification = APNSV3::Notification.new("id", "some message")
          request = APNSV3::Request.new notification
          expect(request.headers).to eq ({"apns-id" => "some_uuid"})
        end
      end

    end

    context "Sending request via APNSv3" do
      it 'create request with something that is not a notification' do
        notification = 22
        expect {APNSV3::Request.new notification}.to raise_error(RuntimeError)
      end

    end

  end

  context "Make request to API with invalid certs" do
    let(:device_token) {"2hudhuwhe273272376-12121hsha"}
    let(:pem) {"example.pem"}
    let(:cert_key) {"a_cert_key"}
    let(:cert) {'a_cert'}
    let(:file_like_object) {double(cert)}
    let(:options) {{:cert_key => cert_key, :cert_pem => pem}}

    it "when making a simple request to the API" do
      class X509Stub
      end

      expect(APNSV3.cert_key).to eq nil
      expect(APNSV3.cert_pem).to eq nil

      NetHttp2::Client.stub(:new)
      OpenSSL::PKey::RSA.stub(:new).and_return('rsa_key')
      OpenSSL::X509::Certificate.stub(:new).and_return(X509Stub.new)

      allow(File).to receive(:open).with('file_name').and_return(file_like_object)
      file_like_object.stub(:read).and_return(cert)

      device_token = "2hudhuwhe273272376-12121hsha"
      expect {APNSV3.send_notification(device_token, "a message", options)}.to raise_error StandardError
    end

    it "when making a requets to the API succeeds" do
      class X509Stub
      end

      class ReponseHttp2
        attr_accessor :code, :headers, :body

        def initialize
          self.code = 500
          self.headers = {}
          self.body = {"some_result": 222}.to_json
        end

        def ok?
          self.code == 200
        end
      end

      class NetHttp2Client
        def call(*args)
          return ReponseHttp2.new
        end
      end

      NetHttp2::Client.stub(:new).and_return(NetHttp2Client.new)
      OpenSSL::PKey::RSA.stub(:new).and_return('rsa_key')
      OpenSSL::X509::Certificate.stub(:new).and_return(X509Stub.new)

      allow(File).to receive(:open).with('file_name').and_return(file_like_object)
      file_like_object.stub(:read).and_return(cert)

      device_token = "2hudhuwhe273272376-12121hsha"
      response = APNSV3.send_notification(device_token, "a message", options)
      expected = {:response => "There was an internal error in the GCM server while trying to process the request.", :status_code => 500}

      expect(APNSV3.cert_key).to eq (cert_key)
      expect(response).to eq expected
    end

    it "when making a requets to the API succeeds" do
      class X509Stub
      end

      class ReponseHttp2
        attr_accessor :code, :headers, :body

        def initialize
          self.code = 200
          self.headers = {}
          self.body = {"some_result": 222}.to_json
        end

        def ok?
          self.code == 200
        end
      end

      class NetHttp2Client
        def call(*args)
          return ReponseHttp2.new
        end
      end

      NetHttp2::Client.stub(:new).and_return(NetHttp2Client.new)
      OpenSSL::PKey::RSA.stub(:new).and_return('rsa_key')
      OpenSSL::X509::Certificate.stub(:new).and_return(X509Stub.new)

      allow(File).to receive(:open).with('file_name').and_return(file_like_object)
      file_like_object.stub(:read).and_return(cert)

      device_token = "2hudhuwhe273272376-12121hsha"
      response = APNSV3.send_notification(device_token, "a message", options)
      expected = {:response => "success", :body => {"some_result" => 222}, :headers => {}, :status_code => 200}
      expect(APNSV3.cert_key).to eq (cert_key)
      expect(response).to eq expected
    end
  end
end