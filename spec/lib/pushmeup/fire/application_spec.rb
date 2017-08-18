require 'spec_helper'

describe Pushmeup do
  describe FIRE::Application do
    let(:host) { FIRE::Application::DEFAULT_FIRE_HOST }
    let(:client_id) { 'client id' }
    let(:client_secret) { 'client secret' }
    let(:access_token) { 'access token' }
    let(:access_token_expiration) { 60 }
    let(:device_token) { 'device token' }
    let(:data) {  { data: {} } }

    describe '#initialize' do
      it 'sets appropriate defaults' do
        fire_app = FIRE::Application.new
        expect(fire_app.host).to eq(FIRE::Application::DEFAULT_FIRE_HOST)
        expect(fire_app.client_id).to be_nil
        expect(fire_app.client_secret).to be_nil
        expect(fire_app.access_token).to be_nil
        expect(fire_app.access_token_expiration).to eq(Time.new(0))
      end

      it 'sets fields appropriately without defaults' do
        fire_app = FIRE::Application.new('different fire host', client_id, client_secret, access_token, access_token_expiration)
        expect(fire_app.host).to eq('different fire host')
        expect(fire_app.client_id).to eq(client_id)
        expect(fire_app.client_secret).to eq(client_secret)
        expect(fire_app.access_token).to eq(access_token)
        expect(fire_app.access_token_expiration).to eq(access_token_expiration)
      end
    end

    describe '#send_notification' do
      context 'without valid access token' do
        it 'raises an exception if it cannot get an access token' do
          stub_request(:post, FIRE::Application::FIRE_TOKEN_URL).to_return(status: 401, body: '')
          fire_app = FIRE::Application.new
          expect { fire_app.send_notification(device_token) }.to raise_error(Exceptions::PushmeupException, 'Error requesting access token from Amazon')
        end
      end

      context 'with valid access token' do
        before do
          stub_request(:post, FIRE::Application::FIRE_TOKEN_URL).to_return(status: 200, body: JSON.dump({ access_token: 'token', expires_in: 60 }))
        end

        it 'return a 200 if successfully sent message to Amazon Fire' do
          stub_request(:post, FIRE::Application::DEFAULT_FIRE_HOST).to_return(status: 200, body: JSON.dump(message: 'success'))
          fire_app = FIRE::Application.new
          response = fire_app.send_notification(device_token)
          expect(response[0][:response]).to eq('success')
        end

        it 'return a 400 if successfully sent message to Amazon Fire' do
          stub_request(:post, FIRE::Application::DEFAULT_FIRE_HOST).to_return(status: 400, body: JSON.dump(message: 'whoops'))
          fire_app = FIRE::Application.new
          response = fire_app.send_notification(device_token)
          expect(response[0][:response]).to eq('Bad request was sent to Amazon Fire')
        end

        it 'return a 401 if successfully sent message to Amazon Fire' do
          stub_request(:post, FIRE::Application::DEFAULT_FIRE_HOST).to_return(status: 401, body: JSON.dump(message: 'whoops'))
          fire_app = FIRE::Application.new
          response = fire_app.send_notification(device_token)
          expect(response[0][:response]).to eq('Error authenticating with Amazon Fire')
        end

        it 'return a 500 if successfully sent message to Amazon Fire' do
          stub_request(:post, FIRE::Application::DEFAULT_FIRE_HOST).to_return(status: 500, body: JSON.dump(message: 'whoops'))
          fire_app = FIRE::Application.new
          response = fire_app.send_notification(device_token)
          expect(response[0][:response]).to eq('Server internal error occurred with Amazon Fire')
        end

        it 'return a 503 if successfully sent message to Amazon Fire' do
          stub_request(:post, FIRE::Application::DEFAULT_FIRE_HOST).to_return(status: 503, body: JSON.dump(message: 'whoops'))
          fire_app = FIRE::Application.new
          response = fire_app.send_notification(device_token)
          expect(response[0][:response]).to eq('Amazon Fire is temporarily unavailable')
        end
      end
    end

    describe '#send_notifications' do
      it 'raises an exception if consolidationKey is present without expiresAfter' do
        stub_request(:post, FIRE::Application::FIRE_TOKEN_URL).to_return(status: 200, body: JSON.dump({ access_token: 'token', expires_in: 60 }))
        fire_app = FIRE::Application.new
        fire_notification = FIRE::Notification.new(device_token, data, { consolidationKey: 'consolidation key' })
        expect { fire_app.send_notifications([fire_notification]) }.to raise_error(Exceptions::PushmeupException, 'Need expiresAfter if consolidationKey is used')
      end

      it 'sends multiple notification' do
        stub_request(:post, FIRE::Application::FIRE_TOKEN_URL).to_return(status: 200, body: JSON.dump({ access_token: 'token', expires_in: 60 }))
        stub_request(:post, FIRE::Application::DEFAULT_FIRE_HOST).to_return(status: 200, body: JSON.dump(message: 'success'))
        fire_app = FIRE::Application.new
        fire_notification1 = FIRE::Notification.new(device_token, data)
        fire_notification2 = FIRE::Notification.new(device_token, data)
        response = fire_app.send_notifications([fire_notification1, fire_notification2])
        expect(response[0][:response]).to eq('success')
        expect(response[1][:response]).to eq('success')
      end
    end
  end
end