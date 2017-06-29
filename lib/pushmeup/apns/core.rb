require 'socket'
require 'openssl'
require 'json'
require 'logger'

module APNS

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil
  
  @persistent = false
  @mutex = Mutex.new
  @retries = 3 # TODO: check if we really need this
  
  @sock = nil
  @ssl = nil
  @logger = nil

  class << self
    attr_accessor :host, :pem, :port, :pass
  end
  
  def self.start_persistence
    @persistent = true
  end
  
  def self.stop_persistence
    @persistent = false

    @ssl.close
    @sock.close
  end
  
  def self.send_notification(device_token, message, options = {})
    _logger_route = options.has_key?("rails_log_route") ? options[:rails_log_route] : STDOUT

    @logger = Logger.new(_logger_route)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n])
  end
  
  def self.send_notifications(notifications)
    @mutex.synchronize do
      self.with_connection do
        notifications.each do |n|
          @logger.debug "[Pushmeup::send_notifications] Writing the following raw request in the ssl socket: #{n.packaged_notification}"
          @ssl.write(n.packaged_notification)
        end
      end
    end
  end
  
  def self.feedback
    sock, ssl = self.feedback_connection
    apns_feedback = []

    @logger.debug "[Pushmeup::feedback] Getting feedback from the API"

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
    
    rescue StandardError, Errno::EPIPE => e

      @logger.debug "[Pushmeup::with_connection] A problem establishing the connection happened. Reason: #{e.to_s}. Backtrace: #{e.backtrace}"

      unless attempts < @retries
        @logger.debug "[Pushmeup::with_connection] Reached maximum retires... Exiting"
        raise "Reached maximum retries"
      end

      @ssl.close unless @ssl.nil?
      @sock.close unless @sock.nil?
    
      attempts += 1
      retry
    end
  
    # Only force close if not persistent
    unless @persistent
      @logger.debug "[Pushmeup::with_connection] Finished successfully. Closing non persistent connection..."
      @ssl.close
      @ssl = nil
      @sock.close
      @sock = nil
    end
  end
  
  def self.open_connection
    unless self.pem
      msg = "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)"
      @logger.debug("[Pushmeup:open_connection] #{msg}")
      raise msg
    end

    unless File.exist?(self.pem)
      msg = "The path to your pem file does not exist!"
      @logger.debug("[Pushmeup:open_connection] #{msg}")
      raise msg
    end
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    @logger.debug "[Pushmeup::with_connection] Successfully set up cert #{context.cert} and key #{context.key}"

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    @logger.debug "[Pushmeup::open_connection] Successfully created the sock ssl connection."
    return sock, ssl
  end
  
  def self.feedback_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    fhost = self.host.gsub('gateway','feedback')
    
    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end
  
end
