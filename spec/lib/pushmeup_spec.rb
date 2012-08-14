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
    
  end
  
  describe "GCM" do
    it "should have a APNS object" do
      defined?(GCM).should_not be_false
    end
  end
end