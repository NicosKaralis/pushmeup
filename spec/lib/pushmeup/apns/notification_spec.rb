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
    end
  end
end