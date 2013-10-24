require 'multi_json'
module APNS
  class Notification
    attr_accessor :device_token, :alert, :badge, :sound, :other

    def initialize(device_token, message)
      self.device_token = device_token
      if message.is_a?(Hash)
        self.alert = message[:alert]
        self.badge = message[:badge]
        self.sound = message[:sound]
        self.other = message[:other]
      elsif message.is_a?(String)
        self.alert = message
      else
        raise "Notification needs to have either a hash or string"
      end
    end

    def packaged_notification
      pt = self.packaged_token
      pm = self.packaged_message
      pm_packed = [pm].pack('a*')
      [1, 1234, (Time.now+1.year).to_i, 0, 32, pt, pm_packed.bytesize, pm].pack("cNNccH*na*")
    end

    def packaged_token
      device_token.gsub(/[\s|<|>]/,'') #] #.pack('H*')
    end

    def packaged_message
      aps = {'aps'=> {} }
      aps['aps']['alert'] = self.alert if self.alert
      aps['aps']['badge'] = self.badge if self.badge
      aps['aps']['sound'] = self.sound if self.sound
      aps.merge!(self.other) if self.other
      aps.to_json #.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*")}
    end

    def ==(that)
      device_token == that.device_token &&
      alert == that.alert &&
      badge == that.badge &&
      sound == that.sound &&
      other == that.other
    end

  end
end
