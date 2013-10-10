require 'socket'
require 'openssl'
require 'json'

module APNS
  class Application

    #Variables
    @host = 'gateway.sandbox.push.apple.com'
    @port = 2195
    # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
    @pem = nil # this should be the path of the pem file not the contentes
    @pass = nil
    @app_id = nil

    #Accessors
    attr_accessor :host, :pem, :port, :pass, :app_id
    
    # Init method
    def initialize (host, pem, port, pass)
      @host=host
      @pem=pem
      @port=port
      @pass=pass
    end

    #Send notification 
    def send_notification(device_token, message)
      n = APNS::Notification.new(device_token, message)
      self.send_notifications([n])
    end
    
    #Send notifications
    def send_notifications(notifications)
      sock, ssl = self.open_connection
      
      notifications.each do |n|
          ssl.write(n.packaged_notification)
        end

      ssl.close
      sock.close
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
      puts fhost
      
      sock         = TCPSocket.new(fhost, 2196)
      ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
      ssl.connect

      return sock, ssl
    end
  end
end
