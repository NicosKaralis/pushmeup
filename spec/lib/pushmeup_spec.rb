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

    it "should open the connection when sending notifications" do
      @APNS.stub(:open_connection)
      @APNS.should_receive(:open_connection)
      @APNS.with_connection { }
    end

    it "should close the connection after every notifications sending" do
      ssl = double("ssl")
      socket = double("socket")
      @APNS.stub(:open_connection)
      @APNS.stub(:ssl) { ssl }
      @APNS.stub(:socket) {socket}
      @APNS.should_receive(:close_socket_and_ssl)
      @APNS.with_connection { }
    end

    it "should close the connection if notifications sending fails" do
      ssl = double("ssl")
      socket = double("socket")
      @APNS.stub(:open_connection)
      @APNS.stub(:ssl) { ssl }
      @APNS.stub(:socket) {socket}
      @APNS.should_receive(:close_socket_and_ssl)
      @APNS.with_connection { 
        raise Errno::EPIPE
      }
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
        n = GCM::Notification.new("id", {:data => "data"})
        
        n.data.is_a?(Hash).should be_true
        n.data.should == {:data => "data"}

        n.data = {:a => ["a", "b", "c"]}
        n.data.is_a?(Hash).should be_true
        n.data.should == {:a => ["a", "b", "c"]}
        
        n.data = {:a => "a"}
        n.data.is_a?(Hash).should be_true
        n.data.should == {:a => "a"}
      end
      
    end
  end
end