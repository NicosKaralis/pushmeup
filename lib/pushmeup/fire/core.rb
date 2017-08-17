require 'httparty'
# require 'cgi'
require 'json'

module FIRE
  class Application
    include HTTParty

    attr_accessor :host, :client_id, :client_secret, :access_token, :access_token_expiration

    def initialize(host = 'https://api.amazon.com/messaging/registrations/%s/messages', client_id = nil, client_secret = nil, access_token_expiration = Time.new(0), access_token = nil)
      @host = host unless host == nil
      @client_id = client_id unless client_id == nil
      @client_secret = client_secret unless client_secret == nil
      @access_token_expiration = access_token_expiration unless access_token_expiration == nil
      @access_token = access_token unless access_token == nil
    end

    def self.send_notification(device_token, data = {}, options = {})
      n = FIRE::Notification.new(device_token, data, options)
      self.send_notifications([n])
    end

    def self.send_notifications(notifications)
      self.prepare_token
      responses = []
      notifications.each do |n|
        responses << self.prepare_and_send(n)
      end
      responses
    end

    def self.prepare_token
      return if Time.now < self.access_token_expiration

      token = self.get_access_token
      self.access_token = token['access_token']
      expires_in_sec    = token['expires_in']
      self.access_token_expiration = Time.now + expires_in_sec - 60
    end

    def self.get_access_token
      headers = {'Content-Type' => 'application/x-www-form-urlencoded'}
      body = {grant_type:    'client_credentials',
              scope:         'messaging:push',
              client_id:     self.client_id,
              client_secret: self.client_secret
      }
      params = {headers: headers, body: body}
      res = self.post('https://api.amazon.com/auth/O2/token', params)
      return res.parsed_response if res.response.code.to_i == 200
      raise 'Error getting access token'
    end

    private

    def self.prepare_and_send(n)
      if !n.consolidationKey.nil? && n.expiresAfter.nil?
        raise %q{If you are defining a "colapse key" you need a "time to live"}
      end
      self.send_push(n)
    end

    def self.send_push(n)
      headers = {
          'Authorization'       => "Bearer #{self.access_token}",
          'Content-Type'        => 'application/json',
          'Accept'              => 'application/json',
          'X-Amzn-Accept-Type'  => 'com.amazon.device.messaging.ADMSendResult@1.0',
          'X-Amzn-Type-Version' => 'com.amazon.device.messaging.ADMMessage@1.0'
      }

      body = {
          :data => n.data
      }
      body.merge!({consolidationKey: n.consolidationKey}) if n.consolidationKey
      body.merge!({expiresAfter: n.expiresAfter}) if n.expiresAfter
      return self.send_to_server(headers, body.to_json, n.device_token)
    end

    def self.send_to_server(headers, body, token)
      params = {:headers => headers, :body => body}
      device_dest = self.host % [token]
      response = self.post(device_dest, params)
      return build_response(response)
    end

    def self.build_response(response)
      case response.code
        when 200
          {:response =>  'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => response.code}
        when 400
          {:response => response.parsed_response, :status_code => response.code}
        when 401
          {:response => 'There was an error authenticating the sender account.', :status_code => response.code}
        when 500
          {:response => 'There was an internal error in the Amazaon server while trying to process the request.', :status_code => response.code}
        when 503
          {:response => 'Server is temporarily unavailable.', :status_code => response.code}
      end
    end
  end
end