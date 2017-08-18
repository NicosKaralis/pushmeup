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
        raise Exception::PushmeupException.new(I18n.t('errors.internal.device_token_must_be_a_string'))
      end
    end

    def data=(data)
      if data.is_a?(Hash)
        @data = data
      else
        raise Exception::PushmeupException.new(I18n.t('errors.internal.data_parameter_must_be_a_hash'))
      end
    end

    def expiresAfter=(expiresAfter)
      if expiresAfter.is_a?(Integer)
        @expiresAfter = expiresAfter
      else
        raise Exception::PushmeupException.new(I18n.t('errors.internal.expires_after_must_be_an_integer'))
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
