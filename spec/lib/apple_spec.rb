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
          expect { APNSV3::Notification.new("id", 2) }.to raise_error Exception
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
        request = APNSV3::Request.new notification
        expect { request.headers }.to raise_error Exception
      end

    end

  end

  context "Make request to API" do
    let(:device_token) { "2hudhuwhe273272376-12121hsha" }
    let(:pem) { StringIO.new "fehuu2671726162nnu2h-generatedpem" }
    let(:cert_key) { "a_cert_key" }

    before(:each) do
      APNSV3.set_cert_key_and_pem cert_key, pem
    end

    context "when making a simple request to the API" do

      # NetHttp2::Client.stub(:new)
      # device_token = "2hudhuwhe273272376-12121hsha"
      # response = APNSV3.send_notification(device_token, "a message")
      #


    end

    context "when making a requets to the API fails" do


    end
  end
end