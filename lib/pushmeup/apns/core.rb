require 'socket'
require 'openssl'
require 'json'

module APNS

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil
  
  class << self
    attr_accessor :host, :pem, :port, :pass
  end
  
  def self.send_notification(device_token, message)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n])
  end
  
  def self.send_notifications(notifications)
    sock, ssl = self.open_connection
    pushmeLog = ActiveSupport::BufferedLogger.new(Rails.root.join('log/pushmeup.log'))
    notifications.each do |n|
      # Write message to APNS
      puts ssl.write(n.packaged_notification)
       pushmeLog.info "Send #{n.device_token}"
       if IO.select([ssl], nil, nil, 1)
        read_buffer = ssl.read(6)
        pushmeLog.info "### Error for: #{n.device_token}"
        # puts "read_buffer:#{read_buffer}"
        # close and reopen connection in case of error
        ssl.close
        sock.close
        sock, ssl = self.open_connection
        # puts "Reopen connection"
      end
    end

    ssl.close
    sock.close
  end
  
  def self.feedback
    sock, ssl = self.feedback_connection

    apns_feedback = []

    while line = ssl.read(38)   # Read lines from the socket
      line.strip!
      f = line.unpack('N1n1H140')
      apns_feedback << { :timestamp => Time.at(f[0]), :token => f[2] }
    end

    ssl.close
    sock.close

    return apns_feedback
  end
  
  protected

  def self.open_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
  def self.feedback_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)
    
    fhost = self.host.gsub('gateway','feedback')
    puts fhost
    
    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end
  
end
