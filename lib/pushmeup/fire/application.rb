require 'httparty'
require 'json'

module FIRE
  class Application
    include HTTParty

    attr_accessor :host, :client_id, :client_secret, :access_token_expiration, :access_token

    DEFAULT_FIRE_HOST = 'https://api.amazon.com/messaging/registrations/messages'.freeze

    FIRE_TOKEN_URL = 'https://api.amazon.com/auth/O2/token'.freeze

    def initialize(host = DEFAULT_FIRE_HOST, client_id = nil, client_secret = nil, access_token = nil, access_token_expiration = Time.new(0))
      @host = host unless host == nil
      @client_id = client_id unless client_id == nil
      @client_secret = client_secret unless client_secret == nil
      @access_token = access_token unless access_token == nil
      @access_token_expiration = access_token_expiration unless access_token_expiration == nil
    end

    def send_notification(device_token, data = {}, options = {})
      notification = FIRE::Notification.new(device_token, data, options)
      send_notifications([notification])
    end

    def send_notifications(notifications)
      prepare_token
      responses = []
      notifications.each do |notification|
        responses << prepare_and_send(notification)
      end
      responses
    end

    def prepare_token
      return if Time.now < @access_token_expiration

      token = get_access_token
      @access_token = token['access_token']
      expires_in_sec = token['expires_in'].to_i
      @access_token_expiration = Time.now + expires_in_sec - 60
    end

    def get_access_token
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      body = {
        grant_type: 'client_credentials',
        scope: 'messaging:push',
        client_id: @client_id,
        client_secret: @client_secret
      }
      params = {headers: headers, body: body}
      result = HTTParty.post(FIRE_TOKEN_URL, params)
      return result.parsed_response if result.response.code.to_i == 200
      raise Exceptions::PushmeupException.new('Error requesting access token from Amazon')
    end

    private
      def prepare_and_send(notification)
        if !notification.consolidationKey.nil? && notification.expiresAfter.nil?
          raise Exceptions::PushmeupException.new('Need expiresAfter if consolidationKey is used')
        end
        send_push(notification)
      end

      def send_push(notification)
        headers = {
          'Authorization'  => "Bearer #{@access_token}",
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-Amzn-Accept-Type' => 'com.amazon.device.messaging.ADMSendResult@1.0',
          'X-Amzn-Type-Version' => 'com.amazon.device.messaging.ADMMessage@1.0'
        }

        body = {
          data: notification.data
        }
        body.merge!({consolidationKey: notification.consolidationKey}) if notification.consolidationKey
        body.merge!({expiresAfter: notification.expiresAfter}) if notification.expiresAfter
        send_to_server(headers, body.to_json, notification.device_token)
      end

      def send_to_server(headers, body, token)
        params = { headers: headers, body: body}
        device_dest = @host % [token]
        response = HTTParty.post(device_dest, params)
        build_response(response)
      end

      def build_response(response)
        case response.code
          when 200
            { response: 'success', body: JSON.parse(response.body), headers: response.headers, status_code: response.code}
          when 400
            { response: 'Bad request was sent to Amazon Fire', status_code: response.code}
          when 401
            { response: 'Error authenticating with Amazon Fire', status_code: response.code}
          when 500
            { response: 'Server internal error occurred with Amazon Fire', status_code: response.code}
          when 503
            { response: 'Amazon Fire is temporarily unavailable', status_code: response.code}
          else
            # Do nothing
        end
      end
  end
end