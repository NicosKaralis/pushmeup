require 'spec_helper'

describe Pushmeup do
  describe "APNS" do
    it "should have a APNS object" do
      defined?(APNS).should_not be_nil
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

        it "should add content-available to data" do
          a = APNS::Notification.new("123", {:alert => "hi", :"content-available" => 1})

          a.packaged_message.should == '{"aps":{"alert":"hi","content-available":1}}'
        end
      end

    end

  end

  describe "GCM" do
    it "should have a GCM object" do
      defined?(GCM).should_not be_nil
    end

    describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
      end

      it "should allow only notifications with device_tokens as array" do
        n = GCM::Notification.new("id", @options)
        expect(n.device_tokens.is_a?(Array)).to eq(true)

        n.device_tokens = ["a" "b", "c"]
        expect(n.device_tokens.is_a?(Array)).to eq(true)

        n.device_tokens = "a"
        expect(n.device_tokens.is_a?(Array)).to eq(true)
      end

      it "should allow only notifications with data as hash with :data root" do
        n = GCM::Notification.new("id", { :data => "data" })

        expect(n.data.is_a?(Hash)).to eq(true)
        n.data.should == {:data => "data"}

        n.data = {:a => ["a", "b", "c"]}
        expect(n.data.is_a?(Hash)).to eq(true)
        n.data.should == {:a => ["a", "b", "c"]}

        n.data = {:a => "a"}
        expect(n.data.is_a?(Hash)).to eq(true)
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