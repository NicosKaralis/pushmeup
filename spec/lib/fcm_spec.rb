require 'spec_helper'

describe 'Pushmeup FCM' do

  module FCM
    module Rails
    end
  end

  class MockLogger
    def info(str)
    end

    def debug(str)
    end
  end

  let(:send_url) {'https://fcm.googleapis.com/fcm/send'}
  let(:group_notification_base_uri) {"https://android.googleapis.com/gcm/notification"}
  let(:api_key) {'AIzaSyB-23h232-1m1jwiuk3wab7ha6aAn4wqIw2'}
  let(:registration_id) {'42'}
  let(:registration_ids) {['42']}
  let(:key_name) {'appUser'}
  let(:project_id) {"123456789"} # https://developers.google.com/cloud-messaging/gcm#senderid
  let(:notification_key) {"APA91bGHXQBB...9QgnYOEURwm0I3lmyqzk2TXQ"}

  context 'module exists' do

    it "should have a fcm object" do
      defined?(FCM).should_not be_false
    end

  end

  context 'sending noritifcations' do

    describe 'sending notification' do
      let(:valid_request_body) do
        {registration_ids: registration_ids}
      end
      let(:valid_request_body_with_string) do
        {registration_ids: registration_id}
      end
      let(:valid_request_headers) do
        {
            'Content-Type' => 'application/json',
            'Authorization' => "key=#{api_key}"
        }
      end

      let(:stub_fcm_send_request) do
        stub_request(:post, send_url).
            with(body: valid_request_body.to_json,
                 headers: {'Authorization' => 'key=', 'Content-Type' => 'application/json'}).
            to_return(status: 200, body: "", headers: {})
      end

      let(:stub_fcm_send_request_with_basic_auth) do
        uri = URI.parse(send_url)
        uri.user = 'a'
        uri.password = 'b'
        stub_request(:post, uri.to_s).to_return(body: '{}', headers: {}, status: 200)
      end

      before(:each) do
        stub_fcm_send_request
        stub_fcm_send_request_with_basic_auth
      end

      it 'should send notification using POST to FCM server' do
        FCM::Rails.stub(:logger).and_return(MockLogger.new)

        FCM.send_notification(registration_ids, {}, {}).should eq(response: 'success', body: {}, headers: {}, status_code: 200, canonical_ids: [], not_registered_ids: [])
        stub_fcm_send_request.should have_been_made.times(1)
      end

      it 'should send notification using POST to FCM if id provided as string' do
        FCM::Rails.stub(:logger).and_return(MockLogger.new)

        FCM.send_notification(registration_id).should eq(response: 'success', body: {}, headers: {}, status_code: 200, canonical_ids: [], not_registered_ids: [])
        stub_fcm_send_request.should have_been_made.times(1)
      end

      context 'send notification with data' do
        let!(:stub_with_data) do
          stub_request(:post, "https://fcm.googleapis.com/fcm/send").
              with(body: "{\"registration_ids\":[\"42\"],\"data\":{\"score\":\"345\",\"time\":\"12:20\"}}",
                   headers: {'Authorization' => 'key=', 'Content-Type' => 'application/json'}).
              to_return(status: 200, body: "", headers: {})
        end
        before do
        end

        it 'should send the data in a post request to fcm' do
          FCM::Rails.stub(:logger).and_return(MockLogger.new)

          FCM.send_notification(registration_ids, {score: '345', time: '12:20'}, {})
          stub_with_data.should have_been_made.times(1)
        end
      end

      context 'when send_notification fails' do
        let(:mock_request_attributes) do
          {
              body: valid_request_body.to_json,
              headers: valid_request_headers
          }
        end

        before(:each) do
          FCM.set_api_key api_key
        end


        context 'on failure code 400' do
          before do
            stub_request(:post, send_url).with(
                mock_request_attributes
            ).to_return(
                # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
                body: '{}',
                headers: {},
                status: 400
            )
          end
          it 'should not send notification due to 400' do
            FCM::Rails.stub(:logger).and_return(MockLogger.new)

            FCM.send_notification(registration_ids).should eq(body: '{}',
                                                              headers: {},
                                                              response: 'Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields.',
                                                              status_code: 400)
          end
        end

        context 'on failure code 401' do
          before do
            stub_request(:post, send_url).with(
                mock_request_attributes
            ).to_return(
                # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
                body: '{}',
                headers: {},
                status: 401
            )
          end

          it 'should not send notification due to 401' do
            FCM::Rails.stub(:logger).and_return(MockLogger.new)

            FCM.send_notification(registration_ids).should eq(body: '{}',
                                                              headers: {},
                                                              response: 'There was an error authenticating the sender account.',
                                                              status_code: 401)
          end
        end

        context 'on failure code 503' do
          before do
            stub_request(:post, send_url).with(
                mock_request_attributes
            ).to_return(
                # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
                body: '{}',
                headers: {},
                status: 503
            )
          end

          it 'should not send notification due to 503' do
            FCM::Rails.stub(:logger).and_return(MockLogger.new)

            FCM.send_notification(registration_ids).should eq(body: '{}',
                                                              headers: {},
                                                              response: 'Server is temporarily unavailable.',
                                                              status_code: 503)
          end
        end

        context 'on failure code 5xx' do
          before do
            stub_request(:post, send_url).with(
                mock_request_attributes
            ).to_return(
                # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
                body: '{"body-key" => "Body value"}',
                headers: {'header-key' => 'Header value'},
                status: 599
            )
          end

          it 'should not send notification due to 599' do
            FCM::Rails.stub(:logger).and_return(MockLogger.new)

            FCM.send_notification(registration_ids).should eq(body: '{"body-key" => "Body value"}',
                                                              headers: {'header-key' => ['Header value']},
                                                              response: 'There was an internal error in the fcm server while trying to process the request.',
                                                              status_code: 599)
          end
        end
      end


    end


  end

end