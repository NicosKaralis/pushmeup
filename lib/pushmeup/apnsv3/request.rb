module APNSV3
  class Request
    attr_reader :path, :headers, :body

    def initialize(notification)
      raise "Request should have a notificaton" unless notification.is_a? APNSV3::Notification
      @path = "/3/device/#{notification.device_token}"
      @headers = build_headers_for notification
      @body = notification.body
    end

    private

    def build_headers_for(notification)
      h = {}
      h.merge!('apns-id' => notification.apns_id) if notification.apns_id
      h.merge!('apns-expiration' => notification.expiration) if notification.expiration
      h.merge!('apns-priority' => notification.priority) if notification.priority
      h.merge!('apns-collapse-id' => notification.apns_collapse_id) if notification.apns_collapse_id
      h.merge!('apns-topic' => notification.topic) if notification.topic
    end
  end
end
