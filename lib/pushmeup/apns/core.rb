require 'socket'
require 'openssl'
require 'json'

module APNS

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem_data = nil
  # this should the content of the pem-cert(String format)
  # changed this because all certs are stored in database
  @pass = nil

  class << self
    attr_accessor :host, :pem_data, :port, :pass
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
  def self.build_connection_context
    raise "Your don't have valid pem data. (APNS.pem = Certificate.development_pem)" unless pem_data
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(self.pem_data)
    context.key  = OpenSSL::PKey::RSA.new(self.pem_data, self.pass)
    context
  end

  def self.open_connection
    context = self.build_connection_context
    sock    = TCPSocket.new(self.host, self.port)
    ssl     = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection
    context = self.build_connection_context
    fhost = self.host.gsub('gateway','feedback')
    puts fhost

    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end

end
