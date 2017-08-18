require 'spec_helper'

describe Pushmeup do
  describe APNS::Notification do
    let(:device_token) { 'device token' }
    let(:message) { { alert: 'alert', badge: 'badge', sound: 'sound', other: 'other' } }

    describe '#initialize' do
      it 'sets values based on a hash' do
        apns_notification = APNS::Notification.new(device_token, message)
        expect(apns_notification.alert).to eq('alert')
        expect(apns_notification.badge).to eq('badge')
        expect(apns_notification.sound).to eq('sound')
        expect(apns_notification.other).to eq('other')
      end

      it 'sets value based on string' do
        apns_notification = APNS::Notification.new(device_token, 'alert2')
        expect(apns_notification.alert).to eq('alert2')
      end

      it 'raise an error if message is not a hash or string' do
        expect { APNS::Notification.new(device_token, 9999) }.to raise_error(Exceptions::PushmeupException, 'Message must either be a Hash or String')
      end
    end
  end
end