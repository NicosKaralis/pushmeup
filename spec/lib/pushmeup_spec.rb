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

      context 'with pem setting' do
        context 'when the pem does not exist' do
          before do
            APNS.pem = '/bad/path'
          end

          it 'fails' do
            expect do
              APNS.send_notification(token, message)
            end.to raise_error(APNS::ConfigurationError, /does not exist/)
          end
        end
      end

      context 'without pem or pem_data' do
        before do
          APNS.pem = nil
        end

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
