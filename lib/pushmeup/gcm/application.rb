require 'httparty'
require 'json'

module GCM
  class Application
    include HTTParty

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
        raise Exception::PushmeupException.new(I18n.t('errors.internal.hash_with_identifier')) if identifier.nil?
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
          raise Exception::PushmeupException.new(I18n.t('errors.internal.invalid_device_token_count', MINIMUM_DEVICE_TOKEN_COUNT, MAXIMUM_DEVICE_TOKEN_COUNT))
        end
        if !notification.collapse_key.nil? && notification.time_to_live.nil?
          raise Exception::PushmeupException.new(I18n.t('errors.internal.collapse_key_without_time_to_live'))
        end
        if @key.is_a?(Hash) && notification.identity.nil?
          raise Exception::PushmeupException.new(I18n.t('errors.internal.hash_with_identifier'))
        end

        if @format == :json
          send_push_as_json(notification)
        elsif @format == :text
          send_push_as_plain_text(notification)
        else
          raise Exception::PushmeupException.new(I18n.t('errors.internal.invalid_notification_format'))
        end
      end

      def send_push_as_json(notification)
        headers = {
          'Authorization' => "key=#{ key(notification.identity) }",
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
        raise Exception::PushmeupException.new(I18n.t('errors.internal.not_yet_implemented'))
      end

      def send_to_server(headers, body)
        params = { headers: headers, body: body}
        response = HTTParty.post(@host, params)
        build_response(response)
      end

      def build_response(response)
        case response.code
          when 200
            {response: I18n.t('success'), body: JSON.parse(response.body), headers: response.headers, status_code: response.code}
          when 400
            {response: I18n.t('errors.response.bad_request', I18n.t('gcm')), status_code: response.code}
          when 401
            {response: I18n.t('errors.response.not_authenticated', I18n.t('gcm')), status_code: response.code}
          when 500
            {response: I18n.t('errors.response.server_internal_error', I18n.t('gcm')), status_code: response.code}
          when 503
            {response: I18n.t('errors.response.temporarily_unavailable', I18n.t('gcm')), status_code: response.code}
          else
            # Do nothing
        end
      end
  end
end