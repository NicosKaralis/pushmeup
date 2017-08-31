require 'httparty'
require 'json'

module GCM
  class Application
    include HTTParty

    attr_accessor :host, :format, :key

    DEFAULT_GCM_HOST = 'https://android.googleapis.com/gcm/send'.freeze

    MINIMUM_DEVICE_TOKEN_COUNT = 1.freeze

    MAXIMUM_DEVICE_TOKEN_COUNT = 1000.freeze

    def initialize(host = DEFAULT_GCM_HOST, format = :json, key = nil)
      @host = host unless host == nil
      @format = format unless format == nil
      @key = key unless key == nil
    end

    def key(identifier = nil)
      if @key.is_a?(Hash)
        raise Exceptions::PushmeupException.new('Hash without identifier') if identifier.nil?
        @key[identifier]
      else
        @key
      end
    end

    def key_identities
      if @key.is_a?(Hash)
        @key.keys
      else
        nil
      end
    end

    def send_notification(device_tokens, data = {}, options = {})
      notification = GCM::Notification.new(device_tokens, data, options)
      send_notifications([notification])
    end

    def send_notifications(notifications)
      responses = []
      notifications.each do |notification|
        responses << prepare_and_send(notification)
      end
      responses
    end

    private
      def prepare_and_send(notification)
        if notification.device_tokens.count < MINIMUM_DEVICE_TOKEN_COUNT || notification.device_tokens.count > MAXIMUM_DEVICE_TOKEN_COUNT
          raise Exceptions::PushmeupException.new("GCM device token count must be between #{MINIMUM_DEVICE_TOKEN_COUNT} and #{MAXIMUM_DEVICE_TOKEN_COUNT}")
        end
        if !notification.collapse_key.nil? && notification.time_to_live.nil?
          raise Exceptions::PushmeupException.new('Need time to live if collapse key is present')
        end
        if @key.is_a?(Hash) && notification.identifier.nil?
          raise Exceptions::PushmeupException.new('Hash without identifier')
        end

        if @format == :json
          send_push_as_json(notification)
        elsif @format == :text
          send_push_as_plain_text(notification)
        else
          raise Exceptions::PushmeupException.new('Invalid notification format')
        end
      end

      def send_push_as_json(notification)
        headers = {
          'Authorization' => "key=#{ key(notification.identifier) }",
          'Content-Type' => 'application/json',
        }
        body = {
          registration_ids: notification.device_tokens,
          data: notification.data,
          collapse_key: notification.collapse_key,
          time_to_live: notification.time_to_live,
          delay_while_idle: notification.delay_while_idle
        }
        send_to_server(headers, body.to_json)
      end

      def send_push_as_plain_text(_notification)
        raise Exceptions::PushmeupException.new('Not yet implemented')
      end

      def send_to_server(headers, body)
        params = { headers: headers, body: body}
        response = HTTParty.post(@host, params)
        build_response(response)
      end

      def build_response(response)
        case response.code
          when 200
            { response: 'success', body: JSON.parse(response.body), headers: response.headers, status_code: response.code}
          when 400
            { response: 'Bad request was sent to GCM', status_code: response.code}
          when 401
            { response: 'Error authenticating with GCM', status_code: response.code}
          when 500
            { response: 'Server internal error occurred with GCM', status_code: response.code}
          when 503
            { response: 'GCM is temporarily unavailable', status_code: response.code}
          else
            # Do nothing
        end
      end
  end
end