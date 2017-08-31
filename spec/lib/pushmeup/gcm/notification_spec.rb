require 'spec_helper'

describe Pushmeup do
  describe GCM::Notification do
    let(:device_token1) { 'device token' }
    let(:device_token2) { 'device token' }
    let(:data) { { data: {} } }
    let(:options) { { collapse_key: 'collapse key', time_to_live: 'time to live', delay_while_idle: 'delay while idle', identifier: 'identifier' } }

    describe '#initialize' do
      it 'sets values based on a hash' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        expect(gcm_notification.device_tokens).to eq([device_token1, device_token2])
        expect(gcm_notification.data).to eq(data)
        expect(gcm_notification.collapse_key).to eq('collapse key')
        expect(gcm_notification.time_to_live).to eq('time to live')
        expect(gcm_notification.delay_while_idle).to eq('delay while idle')
        expect(gcm_notification.identifier).to eq('identifier')
      end

      it 'handles single device token' do
        gcm_notification = GCM::Notification.new(device_token1, data, options)
        expect(gcm_notification.device_tokens).to eq([device_token1])
        expect(gcm_notification.data).to eq(data)
        expect(gcm_notification.collapse_key).to eq('collapse key')
        expect(gcm_notification.time_to_live).to eq('time to live')
        expect(gcm_notification.delay_while_idle).to eq('delay while idle')
        expect(gcm_notification.identifier).to eq('identifier')
      end

      it 'raises error if devise tokens is not a hash or string' do
        expect { GCM::Notification.new({ device_tokens: { } }, data, options) }.to raise_error(Exceptions::PushmeupException, 'Device tokens must be an Array or String')
      end
    end

    describe '#data' do
      it 'raises error if incorrect data format is passed in' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        expect { gcm_notification.data=('test') }.to raise_error(Exceptions::PushmeupException, 'Data must be a Hash')
      end

      it 'raises error if incorrect data format is passed in' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.data=({new_data:{}})
        expect(gcm_notification.data).to eq({new_data:{}})
      end
    end

    describe '#delay_while_idle' do
      it 'sets delay_while_idle to true if true' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.delay_while_idle=(true)
        expect(gcm_notification.delay_while_idle).to be_truthy
      end

      it 'sets delay_while_idle to true if :true' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.delay_while_idle=(:true)
        expect(gcm_notification.delay_while_idle).to be_truthy
      end

      it 'does not sets delay_while_idle to true if not true or :true' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.data=({new_data:{}})
        expect(gcm_notification.delay_while_idle).to eq('delay while idle')
      end
    end

    describe '#device_tokens' do
      it 'sets device_tokens with a single token' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.device_tokens=(device_token1)
        expect(gcm_notification.device_tokens).to eq([device_token1])
      end

      it 'sets device_tokens with multiple tokens' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.device_tokens=([device_token1, device_token2])
        expect(gcm_notification.device_tokens).to eq([device_token1, device_token2])
      end

      it 'raises an error if device_tokens is not an array or string' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        expect { gcm_notification.device_tokens=({ device_tokens: { } }) }.to raise_error(Exceptions::PushmeupException, 'Device tokens must be an Array or String')
      end
    end

    describe '#time_to_live' do
      it 'raises error if incorrect data format is passed in' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        expect { gcm_notification.time_to_live=('test') }.to raise_error(Exceptions::PushmeupException, 'Time to live must be an Integer')
      end

      it 'raises error if incorrect data format is passed in' do
        gcm_notification = GCM::Notification.new([device_token1, device_token2], data, options)
        gcm_notification.time_to_live=(9999)
        expect(gcm_notification.time_to_live).to eq(9999)
      end
    end
  end
end