require 'httparty'

module MPNS
  include HTTParty

  BASEBATCH = { :tile => 1, :toast => 2, :raw => 3 }
  BATCHADDS = { :delay450 => 10, :delay900 => 20 }
  WP_TARGETS = { :toast => "toast", :tile => "token" }

  @pem = nil

  class << self
    attr_accessor :pem
  end

  def self.send_notification(device_url, data = {}, options = {})
    n = MPNS::Notification.new(device_url, data, options)
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
    wp_type = n.type.to_s.capitalize
    notification_class = calculate_delay n.type, n.delay

    headers = { 'Content-Type' => 'text/html', 'X-NotificationClass' => notification_class.to_s }
    headers['X-WindowsPhone-Target'] = WP_TARGETS[n.type] unless n.type == :raw

    body = "<?xml version='1.0' encoding='utf-8'?>"
    unless n.type == :raw
      body << "<wp:Notification xmlns:wp='WPNotification'><wp:#{wp_type}>"
      case n.type
      when :toast
        body << "<wp:Text1>#{n.data[:title]}</wp:Text1>" +
        "<wp:Text2>#{n.data[:message]}</wp:Text2>"
        body << "<wp:Param>#{n.data[:param]}</wp:Param>" if n.data[:param]
      when :tile
        body << "<wp:BackgroundImage>#{n.data[:image]}</wp:BackgroundImage>" if n.data[:image]
        body << "<wp:Count>#{n.data[:count].to_s}</wp:Count>" if n.data[:count]
        body << "<wp:Title>#{n.data[:title]}</wp:Title>" if n.data[:title]
        body << "<wp:BackBackgroundImage>#{n.data[:back_image]}</wp:BackBackgroundImage>" if n.data[:back_image]
        body << "<wp:BackTitle>#{n.data[:back_title]}</wp:BackTitle>" if n.data[:back_title]
        body << "<wp:BackContent>#{n.data[:back_content]}</wp:BackContent>" if n.data[:back_content]
      end
      body << "</wp:#{wp_type}></wp:Notification>"
    else
      body = n.data
    end

    return self.send_to_server(n.device_url,headers, body)
  end

  def self.send_to_server(host, headers, body)
    params = {:headers => headers, :body => body}
    params[:pem] = File.read(self.pem) if self.pem
    response = self.post(host, params)
    return build_response(response)
  end

  def self.build_response(response)
    case response.code
    when 200
      {:response =>  'success', :body => response.body, :headers => response.headers, :status_code => response.code}
    when 401
      {:response => 'There was an error authenticating the sender account.', :status_code => response.code}
    when 404
      {:response => 'Url not found.', :status_code => response.code}
    when 500
      {:response => 'There was an internal error in the GCM server while trying to process the request.', :status_code => response.code}
    when 503
      {:response => 'Server is temporarily unavailable.', :status_code => response.code}
    end
  end

  def self.calculate_delay(type, delay)
    BASEBATCH[type] + (BATCHADDS[delay] || 0)
  end

end
