require 'spec_helper'

describe Pushmeup do
  describe "APNS" do
    it "should have a APNS object" do
      expect(defined?(APNS)).to be_truthy
    end

    it "should not forget the APNS default parameters" do
      expect(APNS.host).to eq("gateway.sandbox.push.apple.com")
      expect(APNS.port).to eq(2195)
      expect(APNS.pem).to be_nil
      expect(APNS.pass).to be_nil
    end

    describe "Notifications" do

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = APNS::Notification.new("123", {:alert => "hi"})
          b = APNS::Notification.new("123", {:alert => "hi"})
          expect(a).to eq(b)
        end

      end

    end

  end

  describe "GCM" do
    it "should have a GCM object" do
      expect(defined?(GCM)).to be_truthy
    end

    describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
      end

      it "should allow only notifications with device_tokens as array" do
        n = GCM::Notification.new("id", @options)
        expect(n.device_tokens).to be_an(Array)

        n.device_tokens = ["a" "b", "c"]
        expect(n.device_tokens).to be_an(Array)

        n.device_tokens = "a"
        expect(n.device_tokens).to be_an(Array)
      end

      it "should allow only notifications with data as hash with :data root" do
        n = GCM::Notification.new("id", { :data => "data" })

        expect(n.data).to be_a(Hash)
        expect(n.data).to eq(:data => "data")

        n.data = {:a => ["a", "b", "c"]}
        expect(n.data).to be_a(Hash)
        expect(n.data).to eq(:a => ["a", "b", "c"])

        n.data = {:a => "a"}
        expect(n.data).to be_a(Hash)
        expect(n.data).to eq(:a => "a")
      end

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = GCM::Notification.new("id", { :data => "data" })
          b = GCM::Notification.new("id", { :data => "data" })
          expect(a).to eq(b)
        end

      end

    end
  end
end