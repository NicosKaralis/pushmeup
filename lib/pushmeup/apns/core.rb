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
    
    notifications.each do |n|
        ssl.write(n.packaged_notification)
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

  def self.pem_data
    raise "Your pem file is not set. (APNS.pem = /path/to/cert.pem or object that responds to read)" unless pem
    if pem.respond_to? :read
      self.pem.read
    else
      raise "The path to your pem file does not exist!" unless File.exist?(@pem)
      File.read(self.pem)
    end
  end

  def self.open_connection
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(self.pem_data)
    context.key  = OpenSSL::PKey::RSA.new(self.pem_data, self.pass)

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
  def self.feedback_connection
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(self.pem_data)
    context.key  = OpenSSL::PKey::RSA.new(self.pem_data, self.pass)
    
    fhost = self.host.gsub('gateway','feedback')
    puts fhost
    
    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end
  
end
