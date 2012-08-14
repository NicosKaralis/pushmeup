require 'httparty'
require 'cgi'
require 'json'

class GCM
  include HTTParty
  
  @host = 'https://android.googleapis.com/gcm/send'
  
  @base_uri = 'https://android.googleapis.com/gcm/send'
  @timeout = 30
  @format = :json
  @key = nil

  class << self
    attr_accessor :base_uri, :timeout, :format, :key
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
  def self.send_notification(registration_ids, options = {})
    post_body = build_post_body(registration_ids, options)

    params = {
      :body => post_body.to_json,
      :headers => {
        'Authorization' => "key=#{@key}",
        'Content-Type' => 'application/json',
      }
    }

    response = self.post(@base_uri, params)
    build_response(response)
    # {body: response.body, headers: response.headers, status: response.code}
  end

  private

  def self.build_post_body(registration_ids, options={})
    body = {:registration_ids => registration_ids}.merge(options)
    #p body
    #raise exception if options[:time_to_live] && !options[:collapse_key]
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