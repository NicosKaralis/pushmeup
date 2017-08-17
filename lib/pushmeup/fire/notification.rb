module FIRE
  class Notification
    attr_accessor :device_token, :data, :consolidationKey, :expiresAfter

    def initialize(token, data, options = {})
      self.device_token = token
      self.data = data

      @consolidationKey = options[:consolidationKey]
      @expiresAfter = options[:expiresAfter]
    end

    def device_token=(token)

      if token.is_a?(String)
        @device_token = token
      else
        raise 'device_token needs to be String'
      end
    end

    def data=(data)
      if data.is_a?(Hash)
        @data = data
      else
        raise 'data parameter must be the type of Hash'
      end
    end

    def expiresAfter=(expiresAfter)
      if expiresAfter.is_a?(Integer)
        @expiresAfter = expiresAfter
      else
        raise %q{"expiresAfter" must be seconds as an integer value, like "100"}
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
