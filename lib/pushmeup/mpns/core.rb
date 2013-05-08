require 'httparty'

module MPNS
  include HTTParty

  def self.send_notification(device_url, title, message = '', data = {}, options = {})
    n = MPNS::Notification.new(device_url, title, message, data, options)
    self.send_notifications([n])
  end

  def self.send_notifications(notifications)
    responses = []
    notifications.each do |n|
      responses << self.send(n)
    end
    responses
  end
  
  protected
  
  def self.send(n)
    return self.send_to_server(n.device_url, n.headers, n.packaged_message)
  end

  def self.send_to_server(url, headers, body)
    params = {:headers => headers, :body => body}
    response = self.post(url, params)
    return build_response(response)
  end

  def self.build_response(response)
    case response.code
      when 200
        {:response =>  'success', :headers => response.headers, :status_code => response.code}
      else
        {:response => response.body, :headers => response.headers, :status_code => response.code}
    end
  end

end
