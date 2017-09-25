require 'net-http2'
require 'openssl'
require 'json'

module APNSV3

  APPLE_DEVELOPMENT_SERVER_URL = "https://api.development.push.apple.com:443"
  APPLE_PRODUCTION_SERVER_URL = "https://api.push.apple.com:443"

  @cert_key = nil # this should be the path of the key file not the contentes
  @cert_pem = nil # this should be the path of the pem file not the contentes

  @mutex = Mutex.new

  class << self
    attr_accessor :host, :cert_pem, :port, :pass, :cert_key, :logger
  end

  def self.send_notification(device_token, message, options = {})


    n = APNSV3::Notification.new(device_token, message)
    self.send_individual_notification(n, options)
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

  def self.set_cert_key_and_pem(cert_key, cert_pem)
    self.log_event "[APNSv3] Setting cert key #{cert_key} with cert_pem #{cert_pem}"
    @cert_pem = cert_pem if @cert_pem.nil?
    @cert_key = cert_key if @cert_key.nil?
  end

  def self.send_individual_notification(notification, options = {})
    @url = options[:url] || APPLE_PRODUCTION_SERVER_URL

    @cert_pem ||= options[:cert_pem] if @cert_pem.nil? and options[:cert_pem]
    @cert_key ||= options[:cert_key] if @cert_key.nil? and options[:cert_key]
    @connect_timeout = options[:connect_timeout] || 30

    @client = NetHttp2::Client.new(@url, ssl_context: self.ssl_context, connect_timeout: @connect_timeout)

    self.check_before_send
    self.send_push(notification)
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

  def self.ssl_context
    @ssl_context ||= begin
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
  end

  def self.certificate
    self.log_event "[APNSv3] Trying to set certificate with content of #{@cert_pem}"
    @certificate ||= begin
      if @cert_pem.respond_to?(:read)
        cert = @cert_pem.read
        @cert_pem.rewind if @cert_pem.respond_to?(:rewind)
      else
        begin
        cert = File.read(@cert_pem)
        rescue SystemCallError => e
        self.log_event "[APNSv3] Does not understand read and its not a path to a file or directory, setting as plain string. Content: #{@cert_pem}"
        cert = @cert_pem
        end
      end
      cert
    end
  end

  def self.check_before_send
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.cert_pem
    raise "The path to your pem file does not exist!" unless self.cert_pem.is_a?(String) and File.exist?(self.cert_pem)

    raise "The path to your key file is not set. (APNS.key = '/path/to/key')" unless self.cert_key
    raise "The path to your apple key file does not exist!" unless File.exist?(self.cert_key)
  end

  def self.send_push(notification)
    self.log_event "[APNSv3] Sending request to APNS server for notification #{notification}"
    request = APNSV3::Request.new(notification)

    response = self.send_to_server(notification, request)
    @client.close if @client
    return response
  end

  def self.send_to_server(notification, request)
    msg = "Error creating http2 client for notification to device #{notification.device_token}"
    self.log_event "[APNSv3] #{msg}"
    raise msg unless @client

    response = @client.call(:post, request.path,
                            body: request.body,
                            headers: request.headers,
                            timeout: options[:timeout]
    )

    self.log_event "[APNSv3] Got response from APNSv3 server parsing response now."
    return self.build_response(response)
  end

  def self.build_response(response)
    unless response.ok?
      self.log_event "[APNSv3] Response not valid. Error code #{response.code}"
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

    self.log_event "[APNSv3] Response successful headers: #{response.headers} and content #{response.body}"
    {:response => 'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => response.code}
  end

  def self.log_event(msg)
    return unless self.logger

    logger.info msg
  end

end