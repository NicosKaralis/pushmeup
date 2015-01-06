require 'spec_helper'

describe Pushmeup do
  describe "APNS" do
    it "should have a APNS object" do
      defined?(APNS).should_not be_nil
    end

    it "should have gateway.sandbox.push.apple.com as default host" do
      APNS.host.eql?("gateway.sandbox.push.apple.com").should be_truthy
    end

    it "should have 2195 as default port" do
      APNS.port.eql?(2195).should be_truthy
    end

    it "should have nil pem by default" do
      APNS.pem.should be_equal(nil)
    end

    it "should have nil password by default" do
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

  end

  describe "GCM" do
    it "should have a GCM object" do
      defined?(GCM).should_not be_nil
    end

    describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
      end

      it "should have https://android.googleapis.com/gcm/send as host by default" do
        GCM.host.eql?("https://android.googleapis.com/gcm/send").should be_truthy
      end

      it "should have json as format by default" do
        GCM.format.eql?(:json).should be_truthy
      end      

      it "should have nil key by default" do
        GCM.key.should be_equal(nil)
      end      

      it "should allow only notifications with device_tokens as array" do
        n = GCM::Notification.new("id", @options)
        n.device_tokens.is_a?(Array).should be_truthy

        n.device_tokens = ["a" "b", "c"]
        n.device_tokens.is_a?(Array).should be_truthy

        n.device_tokens = "a"
        n.device_tokens.is_a?(Array).should be_truthy
      end

      it "should allow only notifications with data as hash with :data root" do
        n = GCM::Notification.new("id", { :data => "data" })

        n.data.is_a?(Hash).should be_truthy
        n.data.should == {:data => "data"}

        n.data = {:a => ["a", "b", "c"]}
        n.data.is_a?(Hash).should be_truthy
        n.data.should == {:a => ["a", "b", "c"]}

        n.data = {:a => "a"}
        n.data.is_a?(Hash).should be_truthy
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