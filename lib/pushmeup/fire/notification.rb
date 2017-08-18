module FIRE
  class Notification
    attr_accessor :device_token, :data, :consolidationKey, :expiresAfter

    def initialize(device_token, data, options = {})
      self.device_token = device_token
      self.data = data

      @consolidationKey = options[:consolidationKey] if options
      @expiresAfter = options[:expiresAfter] if options
    end

    def device_token=(device_token)
      if device_token.is_a?(String)
        @device_token = device_token
      else
        raise Exceptions::PushmeupException.new('Device token must be a String')
      end
    end

    def data=(data)
      if data.is_a?(Hash)
        @data = data
      else
        raise Exceptions::PushmeupException.new('Data must be a Hash')
      end
    end

    def expiresAfter=(expiresAfter)
      if expiresAfter.is_a?(Integer)
        @expiresAfter = expiresAfter
      else
        raise Exceptions::PushmeupException.new('Expires after must be an Integer')
      end
    end

    def ==(that)
      device_token == that.device_token &&
          data == that.data &&
          consolidationKey == that.consolidationKey &&
          expiresAfter == that.expiresAfter
    end
  end
end
