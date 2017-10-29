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
  @ssl_context = nil

  @mutex = Mutex.new

  @host = nil
  @port = 443

  class << self
    attr_accessor :host, :pem, :port, :pass, :logger
  end

  def self.send_notification(device_token, message, options = {})
    _logger_route = options.has_key?("rails_log_route") ? options[:rails_log_route] : STDOUT
    @logger = Logger.new(_logger_route)

    @host = options[:url] || APPLE_PRODUCTION_SERVER_URL
    @port ||= options[:port]
    @pem = options[:pem]
    @pass = options[:pass]

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
    Rails.logger.info "[Pushmeup::APNSV3::send_individual_notification host: #{@host}, port: #{@port}, pem: #{@pem}, pass: #{@pass}"

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

  def self.ssl_context
    @ssl_context ||= begin
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.key = OpenSSL::PKey::RSA.new(self.certificate, @cert_key)
      ctx.cert = OpenSSL::X509::Certificate.new(self.certificate)
      end
      ctx
  end

  def self.certificate
    Rails.logger.debug "[Pushmeup::APNSV3::certificate] Trying to set certificate with content of #{@pem}"
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
    Rails.logger.debug "[Pushmeup::APNSV3::certificate] Returning certificate set #{@certificate}"
    @certificate
  end

  def self.send_push(notification, options)
    Rails.logger.info "[Pushmeup::APNSV3::send_push] Sending request to APNS server for notification #{notification}"
    request = APNSV3::Request.new(notification)

    Rails.logger.info "[APNSv3] Using client instance #{@client}"

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

    status = response.headers[':status'] if response.headers

    if status == '200'
      Rails.logger.info "[Pushmeup::APNSV3::build_response] Response successful headers: #{response.headers} and content #{response.body}"
      {:response => 'success', :body => JSON.parse(response.body), :headers => response.headers, :status_code => status}
    else
      Rails.logger.info "[Pushmeup::APNSV3::build_response] Response . Error code #{status}"
      {:response => 'failure', :body => JSON.parse(response.body), :headers => response.headers, :status_code => status}
    end
  end

end