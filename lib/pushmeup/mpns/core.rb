module MPNS

  @pem = nil

  class << self
    attr_accessor :pem
  end

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
    return self.send_to_server(n.device_url, n.packaged_message)
  end

  def self.send_to_server(url, body)
    # Had to use system call to curl since we could't get client authentication to work from within ruby (Net::HTTP)
    # Details here: http://stackoverflow.com/questions/16603814/connect-to-microsoft-push-notification-service-for-windows-phone-8-from-ruby
    system "curl --cert #{@pem} -H \"Content-Type:text/xml\" -H \"X-WindowsPhone-Target:Toast\" -H \"X-NotificationClass:2\" -X POST -d \"#{body}\" #{url}"
    return build_response($?.success?)
  end

  def self.build_response(response)
    case response
      when true
        {:response =>  'success'}
      else
        {:response => 'failure'}
    end
  end

end
