require 'spec_helper'

describe Pushmeup do
  describe "APNS" do
    it "should have a APNS object" do
      defined?(APNS).should_not be_false
    end

    it "should not forget the APNS default parameters" do
      APNS.host.should == "gateway.sandbox.push.apple.com"
      APNS.port.should == 2195
      APNS.pem.should be_equal(nil)
      APNS.pass.should be_equal(nil)
    end

    describe "Notifications" do

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = APNS::Notification.new("123", {:alert => "hi"})
          b = APNS::Notification.new("123", {:alert => "hi"})
          a.should eq(b)
        end

      end

    end

    describe '.send_notification' do
      let(:token) { 'token' }
      let(:message) { 'message' }
      let(:pem_data) { 'pem_data' }
      let(:cert) { double }
      let(:key) { double }
      let(:sock) { double(close: nil) }
      let(:ssl) { double(connect: nil, write: nil, close: nil) }
      let(:packaged) { 'packaged' }

      after do
        APNS.pem = nil
        APNS.pem_data = nil
      end

      before do
        allow(OpenSSL::X509::Certificate).to receive(:new).
          with(pem_data).and_return(cert)
        allow(OpenSSL::PKey::RSA).to receive(:new).
          with(pem_data, anything).and_return(key)
        allow(TCPSocket).to receive(:new).and_return(sock)
        allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(ssl)
      end

      shared_examples 'notifications' do
        it 'notifications are sent' do
          expect(ssl).to have_received(:write).with(/"#{message}"/)
        end
      end

      context 'with pem setting' do
        context 'with an existing pem file' do
          let(:path) { '/good/path' }

          before do
            allow(File).to receive(:exist?).with(path).and_return(true)
            allow(File).to receive(:read).with(path).and_return(pem_data)
          end

          before { APNS.pem = '/good/path' }
          before { APNS.send_notification(token, message) }

          include_examples 'notifications'
        end

        context 'when the pem does not exist' do
          before { APNS.pem = '/bad/path' }

          it 'fails' do
            expect do
              APNS.send_notification(token, message)
            end.to raise_error(APNS::ConfigurationError, /does not exist/)
          end
        end
      end

      context 'with pem_data' do
        before { APNS.pem_data = pem_data }
        before { APNS.send_notification(token, message) }

        include_examples 'notifications'
      end

      context 'without pem or pem_data' do
        before { APNS.pem = nil }

        it 'fails' do
          expect do
            APNS.send_notification(token, message)
          end.to raise_error(APNS::ConfigurationError, /Supply the path to your pem file, or the binary pem data/)
        end
      end
    end

  end

  describe "GCM" do
    it "should have a GCM object" do
      defined?(GCM).should_not be_false
    end

    describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
      end

      it "should allow only notifications with device_tokens as array" do
        n = GCM::Notification.new("id", @options)
        n.device_tokens.is_a?(Array).should be_true

        n.device_tokens = ["a" "b", "c"]
        n.device_tokens.is_a?(Array).should be_true

        n.device_tokens = "a"
        n.device_tokens.is_a?(Array).should be_true
      end

      it "should allow only notifications with data as hash with :data root" do
        n = GCM::Notification.new("id", { :data => "data" })

        n.data.is_a?(Hash).should be_true
        n.data.should == {:data => "data"}

        n.data = {:a => ["a", "b", "c"]}
        n.data.is_a?(Hash).should be_true
        n.data.should == {:a => ["a", "b", "c"]}

        n.data = {:a => "a"}
        n.data.is_a?(Hash).should be_true
        n.data.should == {:a => "a"}
      end

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = GCM::Notification.new("id", { :data => "data" })
          b = GCM::Notification.new("id", { :data => "data" })
          a.should eq(b)
        end

      end

    end
  end
end
