require 'spec_helper'

describe Pushmeup do
  before(:each) do
    @APNS = APNS::Application.new()
  end

  describe "APNS" do
    
    it "should not forget the APNS default parameters" do
      puts @APNS
      @APNS.host.should == 'gateway.sandbox.push.apple.com'
      @APNS.port.should == 2195
      @APNS.pem.should be_equal(nil)
      @APNS.pass.should be_equal(nil)
    end

    it "should open the connection when sending notifications" do
      @APNS.stub(:open_connection)
      @APNS.should_receive(:open_connection)
      @APNS.with_connection { }
    end
    
  end
  
  describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
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
    end
end