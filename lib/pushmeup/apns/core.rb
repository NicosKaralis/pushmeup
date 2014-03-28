require 'socket'
require 'openssl'
require 'json'

module APNS

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem          = nil # this should be the path of the pem file not the contents
  @pem_contents = nil # this should be the contents of a specific pem
  @pass         = nil

  class << self
    attr_accessor :host, :pem, :pem_contents, :port, :pass
  end

  def self.send_notification(device_token, message, alternate_pem=nil)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n], alternate_pem)
  end

  def self.send_notifications(notifications, alternate_pem=nil)
    set_pem_contents(alternate_pem)
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

  def self.set_pem_contents(alternate_pem)
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" if !self.pem && !alternate_pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem) || alternate_pem
    self.pem_contents = alternate_pem || File.read(self.pem)
  end

  def self.open_connection
    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, self.context)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection
    fhost = self.host.gsub('gateway','feedback')

    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, self.context)
    ssl.connect

    return sock, ssl
  end

  def self.context
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(self.pem_contents)
    context.key  = OpenSSL::PKey::RSA.new(self.pem_contents, self.pass)
    return context
  end

end
