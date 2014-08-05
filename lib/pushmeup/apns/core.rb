require 'socket'
require 'openssl'
require 'json'

module APNS
  class Application

    #Accessors
    attr_accessor :host, :pem, :port, :pass, :app_id
    
    # Socket attributes
    @sock = nil
    @ssl = nil

    # Persistance attributes
    @persistent = false
    @mutex = Mutex.new

    # Init method
    def initialize (host='gateway.sandbox.push.apple.com', pem=nil, port=2195, pass=nil, persistent = false)
      @host = host unless host == nil
      @pem = pem unless pem == nil
      @port = port unless port == nil
      @pass = pass unless pass == nil
      @persistent = persistent
    end

    # Send notification 
    def send_notification(device_token, message)
      n = APNS::Notification.new(device_token, message)
      self.send_notifications([n])
    end
    
    # Send notifications
    def send_notifications(notifications)
      @mutex.synchronize do
        self.with_connection do
          notifications.each do |n|
            @ssl.write(n.packaged_notification)
          end
        end
      end
    end
    
    def feedback
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

    # Connection initialization and notifications sending
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

    def open_connection
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
    
    def feedback_connection
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
end
