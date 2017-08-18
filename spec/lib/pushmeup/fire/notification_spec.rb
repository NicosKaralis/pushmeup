require 'spec_helper'

describe Pushmeup do
  describe FIRE::Notification do
    let(:device_token) { 'device token' }
    let(:data) { { data: {} } }
    let(:options) {  }
    let(:expiresAfter) { 999 }

    describe '#initialize' do
      it 'sets values appropriately' do
        fire_notification = FIRE::Notification.new(device_token, data, { consolidationKey: 'consolidation key', expiresAfter: 999 })
        expect(fire_notification.device_token).to eq(device_token)
        expect(fire_notification.data).to eq(data)
        expect(fire_notification.consolidationKey).to eq('consolidation key')
        expect(fire_notification.expiresAfter).to eq(999)
      end
    end

    describe '#data' do
      it 'raises error if incorrect data format is passed in' do
        fire_notification = FIRE::Notification.new(device_token, data, options)
        expect { fire_notification.data=('test') }.to raise_error(Exceptions::PushmeupException, 'Data must be a Hash')
      end

      it 'raises error if incorrect data format is passed in' do
        fire_notification = FIRE::Notification.new(device_token, data, options)
        fire_notification.data=({new_data:{}})
        expect(fire_notification.data).to eq({new_data:{}})
      end
    end

    describe '#device_token' do
      it 'sets device_token with a single token' do
        fire_notification = FIRE::Notification.new(device_token, data, options)
        fire_notification.device_token=(device_token)
        expect(fire_notification.device_token).to eq(device_token)
      end

      it 'raises an error if device_token is not a string' do
        fire_notification = FIRE::Notification.new(device_token, data, options)
        expect { fire_notification.device_token=({ device_token: { } }) }.to raise_error(Exceptions::PushmeupException, 'Device token must be a String')
      end
    end

    describe '#expiresAfter' do
      it 'sets expiresAfter' do
        fire_notification = FIRE::Notification.new(device_token, data, options)
        fire_notification.expiresAfter=(expiresAfter)
        expect(fire_notification.expiresAfter).to eq(expiresAfter)
      end

      it 'raises an error if expiresAfter is not an Integer' do
        fire_notification = FIRE::Notification.new(device_token, data, options)
        expect { fire_notification.expiresAfter=('not an int') }.to raise_error(Exceptions::PushmeupException, 'Expires after must be an Integer')
      end
    end
  end
end