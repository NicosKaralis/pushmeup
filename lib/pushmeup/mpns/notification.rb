module MPNS
  class Notification
    attr_accessor :device_url, :data, :type, :delay

    def initialize(device_url, data, options = {})
      self.device_url = device_url
      self.data = data

      self.type = options[:type] || :raw
      self.delay = options[:delay]
    end

  end
end
