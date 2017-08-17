require 'httparty'
# require 'cgi'
require 'json'

module GCM
  class Application
    include HTTParty

    attr_accessor :host, :format, :key

    def initialize(host = 'https://android.googleapis.com/gcm/send', format = :json, key = nil)
      @host = host unless host == nil
      @format = format unless format == nil
      @key = key unless key == nil
    end

    def key(identity = nil)
      if @key.is_a?(Hash)
        raise %{If your key is a hash of keys you'l need to pass a identifier to the notification!} if identity.nil?
        @key[identity]
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
  end

  def self.send_notification(device_tokens, data = {}, options = {})
    n = GCM::Notification.new(device_tokens, data, options)
    self.send_notifications([n])
  end

  def self.send_notifications(notifications)
    responses = []
    notifications.each do |n|
      responses << self.prepare_and_send(n)
    end
    responses
  end

  private
    def self.prepare_and_send(n)
      if n.device_tokens.count < 1 || n.device_tokens.count > 1000
        raise 'Number of device_tokens invalid, keep it betwen 1 and 1000'
      end
      if !n.collapse_key.nil? && n.time_to_live.nil?
        raise %q{If you are defining a "colapse key" you need a "time to live"}
      end
      if @key.is_a?(Hash) && n.identity.nil?
        raise %{If your key is a hash of keys you'l need to pass a identifier to the notification!}
      end

      if self.format == :json
        self.send_push_as_json(n)
      elsif self.format == :text
        self.send_push_as_plain_text(n)
      else
        raise 'Invalid format'
      end
    end

    def self.send_push_as_json(n)
      headers = {
        'Authorization' => "key=#{ self.key(n.identity) }",
        'Content-Type' => 'application/json',
      }
      body = {
        :registration_ids => n.device_tokens,
        :data => n.data,
        :collapse_key => n.collapse_key,
        :time_to_live => n.time_to_live,
        :delay_while_idle => n.delay_while_idle
      }
      return self.send_to_server(headers, body.to_json)
    end

    def self.send_push_as_plain_text(n)
      raise 'Still has to be done: http://developer.android.com/guide/google/gcm/gcm.html'
      headers = {
        # TODO: Aceitar key ser um hash
        'Authorization' => "key=#{ self.key(n.identity) }",
        'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
      }
      return self.send_to_server(headers, body)
    end

    def self.send_to_server(headers, body)
      params = {:headers => headers, :body => body}
      response = self.post(self.host, params)
      return build_response(response)
    end

    def self.build_response(response)
      case response.code
        when 200
          {:response =>  'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => response.code}
        when 400
          {:response => 'Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields.', :status_code => response.code}
        when 401
          {:response => 'There was an error authenticating the sender account.', :status_code => response.code}
        when 500
          {:response => 'There was an internal error in the GCM server while trying to process the request.', :status_code => response.code}
        when 503
          {:response => 'Server is temporarily unavailable.', :status_code => response.code}
      end
    end
end