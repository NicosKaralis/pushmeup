require 'spec_helper'

describe Pushmeup do
  before(:each) do
    @APNS = APNS::Application.new()
  end

  describe "APNS" do
    it "should have a APNS object" do
      defined?(@APNS).should_not be_false
    end

    it "should not forget the APNS default parameters" do
      puts @APNS
      @APNS.host.should == 'gateway.sandbox.push.apple.com'
      @APNS.port.should == 2195
      @APNS.pem.should be_equal(nil)
      @APNS.pass.should be_equal(nil)
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