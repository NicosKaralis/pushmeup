require 'socket'
require 'openssl'

module APNS
  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195

  class << self
    attr_accessor :host, :pem, :port, :pass

    # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
    def pem=(val)
      @ssl_context = nil
      @pem = val
    end

    def pass=(val)
      @ssl_context = nil
      @pass = val
    end

    def send_notification(device_token, message)
      n = APNS::Notification.new(device_token, message)
      send_notifications([n])
    end

    def send_notifications(notifications)
      open_connection do |ssl|
        notifications.each do |n|
          ssl.write(n.packaged_notification)
        end
      end
    end

    def feedback
      feedback_connection do |ssl|
        apns_feedback = []
        while line = ssl.read(38)   # Read lines from the socket
          line.strip!
          f = line.unpack('N1n1H140')
          apns_feedback << { :timestamp => Time.at(f[0]), :token => f[2] }
        end
        apns_feedback
      end
    end

    protected
      def open_connection(&block)
        ssl_connection(&block)
      end

      def feedback_connection(&block)
        fhost = host.gsub('gateway','feedback')
        ssl_connection(fhost, 2196, &block)
      end

      def ssl_connection(host = nil, port = nil)
        sock         = TCPSocket.new(host || self.host, port || self.port)
        ssl          = OpenSSL::SSL::SSLSocket.new(sock, ssl_context)
        ssl.connect

        return sock, ssl unless block_given?
        begin
          yield ssl
        ensure
          ssl.close
          sock.close
        end
      end

      def ssl_context
        @ssl_context ||= begin
          raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless pem
          raise "The path to your pem file does not exist!" unless File.exist?(pem)

          pem_content   = File.read(pem)
          context       = OpenSSL::SSL::SSLContext.new
          context.cert  = OpenSSL::X509::Certificate.new(pem_content)
          context.key   = OpenSSL::PKey::RSA.new(pem_content, pass)
          context
        end
      end
  end
end
