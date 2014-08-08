require 'socket'
require 'openssl'
require 'json'

module APNS

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pem_contents = nil # this should be the contents of a specific pem
  @pass = nil

  @persistent = false
  @mutex = Mutex.new
  @retries = 3 # TODO: check if we really need this

  @sock = nil
  @ssl = nil

  class << self
    attr_accessor :host, :pem, :pem_contents, :port, :pass
  end

  def self.start_persistence
    @persistent = true
  end

  def self.stop_persistence
    @persistent = false

    @ssl.close
    @sock.close
  end

  def self.send_notification(device_token, message, alternate_pem=nil)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n], alternate_pem)
  end

  def self.send_notifications(notifications)
    set_pem_contents(alternate_pem)
    @mutex.synchronize do
      self.with_connection do
        notifications.each do |n|
          @ssl.write(n.packaged_notification)
        end
      end
    end
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
  def self.with_connection
    attempts = 1

    begin
      # If no @ssl is created or if @ssl is closed we need to start it
      if @ssl.nil? || @sock.nil? || @ssl.closed? || @sock.closed?
        @sock, @ssl = self.open_connection
      end

      yield

    rescue StandardError, Errno::EPIPE
      raise unless attempts < @retries

      @ssl.close
      @sock.close

      attempts += 1
      retry
    end

    # Only force close if not persistent
    unless @persistent
      @ssl.close
      @ssl = nil
      @sock.close
      @sock = nil
    end
  end

  def self.open_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

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
