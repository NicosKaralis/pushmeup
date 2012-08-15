require 'httparty'
# require 'cgi'
require 'json'

module GCM
  include HTTParty
  
  @host = 'https://android.googleapis.com/gcm/send'
  @key = nil
  @format = :json

  class << self
    attr_accessor :host, :format, :key
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
  
  # {
  # "collapse_key": "score_update",
  # "time_to_live": 108,
  # "delay_while_idle": true,
  # "registration_ids": ["4", "8", "15", "16", "23", "42"],
  # "data" : {
  # "score": "5x1",
  # "time": "15:10"
  # }
  # }
  # gcm = GCM.new(api_key)
  # gcm.send_notification({registration_ids: ["4sdsx", "8sdsd"], data: {score: "5x1"}})

  # def self.send_notification(registration_ids, options = {})
  #   post_body = build_post_body(registration_ids, options)
  # 
  #   type = (@format == :json) ? 'application/json' : 'application/x-www-form-urlencoded;charset=UTF-8'
  # 
  #   params = {
  #     :body => post_body.to_json,
  #     :headers => {
  #       'Authorization' => "key=#{@key}",
  #       'Content-Type' => type,
  #     }
  #   }
  # 
  #   response = self.post(@base_uri, params)
  #   build_response(response)
  #   # {body: response.body, headers: response.headers, status: response.code}
  # end

  private
  
  def self.prepare_and_send(n)
    if n.device_tokens.count < 1 || n.device_tokens.count > 1000
      raise "Number of device_tokens invalid, keep it betwen 1 and 1000"
    end
    if !n.collapse_key.nil? && n.time_to_live.nil?
      raise %q{If you are defining a "colapse key" you need a "time to live"}
    end
    
    if self.format == :json
      self.send_push_as_json(n)
    elsif self.format == :text
      self.send_push_as_plain_text(n)
    else
      raise "Invalid format"
    end
  end
  
  def self.send_push_as_json(n)
    headers = {
      'Authorization' => "key=#{self.key}",
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
    raise "To be done: http://developer.android.com/guide/google/gcm/gcm.html"
    headers = {
      'Authorization' => "key=#{self.key}",
      'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
    }
    return self.send_to_server(headers, body)
  end
  
  def self.send_to_server(headers, body)
    params = {:headers => headers, :body => body}
    response = self.post('https://android.googleapis.com/gcm/send', params)
    return build_response(response)
  end
  
  def self.build_response(response)
    case response.code
      when 200
        {:response =>  'success', :body => response.body, :headers => response.headers, :status_code => response.code}
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