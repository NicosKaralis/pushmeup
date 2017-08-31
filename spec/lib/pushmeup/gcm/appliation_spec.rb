require 'spec_helper'

describe Pushmeup do
  describe GCM::Application do
    let(:host) { GCM::Application::DEFAULT_GCM_HOST }
    let(:format) { :json }
    let(:key) { 'fake GCM key' }
    let(:device_token) { 'fake device token' }
    let(:device_token2) { 'fake device token2' }
    let(:payload) { { payload: 'payload' } }

    describe '#initialize' do
      it 'defaults values appropriately' do
        gcm_app = GCM::Application.new
        expect(gcm_app.host).to eq(GCM::Application::DEFAULT_GCM_HOST)
        expect(gcm_app.format).to eq(:json)
        expect(gcm_app.key).to be_nil
      end

      it 'sets values appropriately with initializer' do
        gcm_app = GCM::Application.new('new GCM host', :format, key)
        expect(gcm_app.host).to eq('new GCM host')
        expect(gcm_app.format).to eq(:format)
        expect(gcm_app.key).to eq(key)
      end
    end

    describe '#key' do
      it 'sets key with a string' do
        gcm_app = GCM::Application.new(host, format, key)
        expect(gcm_app.key).to eq(key)
      end

      it 'sets key via a hash and identifier' do
        gcm_app = GCM::Application.new(host, format, { identifier: key })
        expect(gcm_app.key(:identifier)).to eq(key)
      end

      it 'raises an error if a hash is passed in without an identifier' do
        gcm_app = GCM::Application.new(host, format, { identifier: key })
        expect{ gcm_app.key }.to raise_error(Exceptions::PushmeupException, 'Hash without identifier')
      end
    end

    describe '#send_notification' do
      it 'raises an exception if the number of device tokens is invalid' do
        gcm_app = GCM::Application.new(host, format, key)
        expect { gcm_app.send_notification([]) }.to raise_error(Exceptions::PushmeupException, 'GCM device token count must be between 1 and 1000')
      end

      it 'raises an exception if format is not valid' do
        gcm_app = GCM::Application.new(host, :crazy_format, key)
        expect {  gcm_app.send_notification(device_token) }.to raise_error(Exceptions::PushmeupException, 'Invalid notification format')
      end

      it 'raises an exception if key is a hash without an identifier' do
        gcm_app = GCM::Application.new(host, format, {})
        expect {  gcm_app.send_notification(device_token) }.to raise_error(Exceptions::PushmeupException, 'Hash without identifier')
      end

      it 'return a 200 if successfully sent message to GCM' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 200, body: JSON.dump(message: 'success'))
        gcm_app = GCM::Application.new(host, format, key)
        response = gcm_app.send_notification(device_token)
        expect(response[0][:response]).to eq('success')
      end

      it 'return a 400 if successfully sent message to GCM' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 400, body: JSON.dump(message: 'whoops'))
        gcm_app = GCM::Application.new(host, format, key)
        response = gcm_app.send_notification(device_token)
        expect(response[0][:response]).to eq('Bad request was sent to GCM')
      end

      it 'return a 401 if successfully sent message to GCM' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 401, body: JSON.dump(message: 'whoops'))
        gcm_app = GCM::Application.new(host, format, key)
        response = gcm_app.send_notification(device_token)
        expect(response[0][:response]).to eq('Error authenticating with GCM')
      end

      it 'return a 500 if successfully sent message to GCM' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 500, body: JSON.dump(message: 'whoops'))
        gcm_app = GCM::Application.new(host, format, key)
        response = gcm_app.send_notification(device_token)
        expect(response[0][:response]).to eq('Server internal error occurred with GCM')
      end

      it 'return a 503 if successfully sent message to GCM' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 503, body: JSON.dump(message: 'whoops'))
        gcm_app = GCM::Application.new(host, format, key)
        response = gcm_app.send_notification(device_token)
        expect(response[0][:response]).to eq('GCM is temporarily unavailable')
      end
    end

    describe '#send_notifications' do
      it 'raises error if collapse_key is present without time_to_live' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 200, body: JSON.dump(message: 'success'))
        gcm_app = GCM::Application.new(host, format, key)
        gcm_notification = GCM::Notification.new(device_token, payload, { collapse_key: 'collapse_key' })
        expect { gcm_app.send_notifications([gcm_notification]) }.to raise_error(Exceptions::PushmeupException, 'Need time to live if collapse key is present')
      end

      it 'handles sending multiple notifications' do
        stub_request(:post, GCM::Application::DEFAULT_GCM_HOST).to_return(status: 200, body: JSON.dump(message: 'success'))
        gcm_app = GCM::Application.new(host, format, key)
        gcm_notification1 = GCM::Notification.new(device_token, payload)
        gcm_notification2 = GCM::Notification.new(device_token2, payload)
        response = gcm_app.send_notifications([gcm_notification1, gcm_notification2])
        expect(response[0][:response]).to eq('success')
        expect(response[1][:response]).to eq('success')
      end
    end

    describe '#send_push_as_plain_text' do
      it 'raises an error' do
        gcm_app = GCM::Application.new(host, :text, key)
        expect { gcm_app.send_notification(device_token) }.to raise_error(Exceptions::PushmeupException, 'Not yet implemented')
      end
    end
  end
end