require 'spec_helper'

describe Pushmeup do
  describe 'APNS' do
    it 'has a APNS object' do
      expect(defined?(APNS)).to be_truthy
    end

    it 'doesn\'t forget the APNS default parameters' do
      expect(APNS.host).to eql('gateway.sandbox.push.apple.com')
      expect(APNS.port).to eql(2195)
      expect(APNS.pem).to be_nil
      expect(APNS.pass).to be_nil
    end

    context 'Notifications' do
      context '#==' do
        it 'properly equates objects without caring about object identity' do
          a = APNS::Notification.new('123', {alert: '123'})
          b = APNS::Notification.new('123', {alert: '123'})
          expect(a).to eq(b)
        end
      end
    end
  end

  describe 'GCM' do
    it 'has a GCM object' do
      expect(defined?(GCM)).to be_truthy
    end

    context 'Notifications' do
      let(:options) { {data: 'dummy data'} }

      it 'allows only notifications with device_tokens as array' do
        n = GCM::Notification.new('id', options)
        expect(n.device_tokens).to be_an(Array)

        n.device_tokens = ['a', 'b', 'c']
        expect(n.device_tokens).to be_an(Array)

        n.device_tokens = 'a'
        expect(n.device_tokens).to be_an(Array)
      end

      it 'allows only notifications with data as hash with :data root' do
        n = GCM::Notification.new('id', options)

        expect(n.data).to be_a(Hash)
        expect(n.data).to eql(options)

        n.data = {a: ['a', 'b', 'c']}
        expect(n.data).to be_a(Hash)
        expect(n.data).to eql(a: ['a', 'b', 'c'])

        n.data = {a: "a"}
        expect(n.data).to be_a(Hash)
        expect(n.data).to eql(a: 'a')
      end

      context '#==' do
        it 'properly equates objects without caring about object identity' do
          a = GCM::Notification.new('id', { data: 'data' })
          b = GCM::Notification.new('id', { data: 'data' })
          expect(a).to eq(b)
        end
      end
    end
  end
end
