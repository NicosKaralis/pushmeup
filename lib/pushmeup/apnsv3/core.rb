require 'net-http2'
require 'openssl'
require 'json'
require 'logger'


module APNSV3

  APPLE_DEVELOPMENT_SERVER_URL = "https://api.development.push.apple.com"
  APPLE_PRODUCTION_SERVER_URL = "https://api.push.apple.com"

  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil
  @certificate = nil

  @mutex = Mutex.new

  @host = nil
  @port = 443

  class << self
    attr_accessor :host, :pem, :port, :pass, :logger
  end

  def self.send_notification(device_token, message, options = {})
    _logger_route = options.has_key?("rails_log_route") ? options[:rails_log_route] : STDOUT
    @logger = Logger.new(_logger_route)

    n = APNSV3::Notification.new(device_token, message)
    self.send_notifications([n], options)
  end

  def self.send_notifications(notifications, options = {})
    @mutex.synchronize do
      self.with_connection do
        notifications.each do |n|
          self.send_individual_notification(n, options)
        end
      end
    end
  end

  def self.send_individual_notification(notification, options = {})
    @host = options[:url] || APPLE_PRODUCTION_SERVER_URL
    @port ||= options[:port]
    @pem = options[:pem]
    @pass = options[:pass]

    @connect_timeout = options[:connect_timeout] || 30
    @client = NetHttp2::Client.new(@host, ssl_context: self.ssl_context, connect_timeout: @connect_timeout)
    self.send_push(notification, options)
  end


  protected

  def self.with_connection
    attempts = 1
    @retries ||= 3

    begin
      # If no @ssl is created or if @ssl is closed we need to start it
      if @ssl_context.blank?
        @ssl_context = self.ssl_context
      end

      yield

    rescue StandardError
      raise unless attempts < @retries

      attempts += 1
      retry
    end

    # Only force close if not persistent
    unless @persistent
      @ssl_context.close
      @ssl_context = nil
      @client.close
    end
  end


  def self.open_connection
    unless self.pem
      msg = "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)"
      @logger.debug("[Pushmeup::APNSV3::open_connection] #{msg}")
      raise msg
    end

    unless File.exist?(self.cert_pem)
      msg = "The path to your pem file does not exist!"
      @logger.debug("[Pushmeup::APNSV3::open_connection] #{msg}")
      raise msg
    end

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    @logger.debug "[Pushmeup::with_connection] Successfully set up cert #{context.cert} and key #{context.key}"

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    @logger.debug "[Pushmeup::APNSV3::open_connection] Successfully created the sock ssl connection."
    return sock, ssl
  end


  def self.ssl_context
      ctx = OpenSSL::SSL::SSLContext.new
      begin
        p12 = OpenSSL::PKCS12.new(self.certificate, @cert_key)
        ctx.key = p12.key
        ctx.cert = p12.certificate
      rescue OpenSSL::PKCS12::PKCS12Error
        ctx.key = OpenSSL::PKey::RSA.new(self.certificate, @cert_key)
        ctx.cert = OpenSSL::X509::Certificate.new(self.certificate)
      end
      ctx
  end

  def self.certificate
    Rails.logger.info "[Pushmeup::APNSV3::certificate] Trying to set certificate with content of #{@pem}"
    unless @certificate
      if @pem.respond_to?(:read)
        cert = @pem.read
        @pem.rewind if @pem.respond_to?(:rewind)
      else
        begin
          cert = File.read(@pem)
        rescue SystemCallError => e
          Rails.logger.info "[Pushmeup::APNSV3::certificate] Does not understand read and its not a path to a file or directory, setting as plain string. Content: #{@cert_pem}"
          cert = @pem
        end
      end
      @certificate = cert
    end
    Rails.logger.info "[APNSv3] Returning certificate set #{@certificate}"
    @certificate
  end

  def self.send_push(notification, options)
    Rails.logger.info "[Pushmeup::APNSV3::send_push] Sending request to APNS server for notification #{notification}"
    request = APNSV3::Request.new(notification)

    self.log_event "[APNSv3] Using client instance #{@client}"

    response = self.send_to_server(notification, request, options)
    @client.close if @client and @client.respond_to? :close
    return response
  end

  def self.send_to_server(notification, request, options)
    if @client.nil?
      msg = "Error creating http2 client for notification to device #{notification.device_token}"
      Rails.logger.info "[Pushmeup::APNSV3::send_to_server] #{msg}"
      raise msg
    end

    Rails.logger.info "[Pushmeup::APNSV3::send_to_server] Adding post to path #{request.path}, with headers #{request.headers} and body #{request.body}"

    response = @client.call(:post, request.path,
                            body: request.body,
                            headers: request.headers,
                            timeout: options[:timeout]
    )

    Rails.logger.info "[Pushmeup::APNSV3::send_to_server] Got response from APNSv3 server parsing response now."
    return self.build_response(response)
  end

  def self.build_response(response)
    unless response.ok?
      Rails.logger.info "[Pushmeup::APNSV3::build_response] Response not valid. Error code #{response.code}"
      return case response.code
               when 400
                 {:response => 'Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields. Bad request', :status_code => response.code}
               when 403
                 {:response => 'There was an error with the certificate or with the provider authentication token.', :status_code => response.code}
               when 405
                 {:response => 'The request used a bad :method value. Only POST requests are supported.', :status_code => response.code}
               when 410
                 {:response => 'The device token is no longer active for the topic.', :status_code => response.code}
               when 413
                 {:response => 'The notification payload was too large.', :status_code => response.code}
               when 429
                 {:response => 'The server received too many requests for the same device token.', :status_code => response.code}
               when 500
                 {:response => 'There was an internal error in the GCM server while trying to process the request.', :status_code => response.code}
               when 503
                 {:response => 'Server is temporarily unavailable.', :status_code => response.code}
               else
                 {:response => 'Unknown Error.', :status_code => response.code}
             end
    end

    Rails.logger.info "[Pushmeup::APNSV3::build_response] Response successful headers: #{response.headers} and content #{response.body}"
    {:response => 'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => response.code}
  end

end