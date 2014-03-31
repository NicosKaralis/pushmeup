module GCM
  class Notification
    attr_accessor :device_tokens, :data, :collapse_key, :time_to_live, :delay_while_idle, :identity

    def initialize(tokens, data, options = {})
      self.device_tokens = tokens
      self.data = data

      @collapse_key = options[:collapse_key]
      @time_to_live = options[:time_to_live]
      @delay_while_idle = options[:delay_while_idle]
      @identity = options[:identity]
    end

    def device_tokens=(tokens)
      if tokens.is_a?(Array)
        @device_tokens = tokens
      elsif tokens.is_a?(String)
        @device_tokens = [tokens]
      else
        raise "device_tokens needs to be either a Hash or String"
      end
    end

    def data=(data)
      if data.is_a?(Hash)
        @data = data
      else
        raise "data parameter must be the type of Hash"
      end
    end

    def delay_while_idle=(delay_while_idle)
      @delay_while_idle = (delay_while_idle == true || delay_while_idle == :true)
    end

    def time_to_live=(time_to_live)
      if time_to_live.is_a?(Integer)
        @time_to_live = time_to_live
      else
        raise %q{"time_to_live" must be seconds as an integer value, like "100"}
      end
    end

    def ==(that)
      device_tokens == that.device_tokens &&
      data == that.data &&
      collapse_key == that.collapse_key &&
      time_to_live == that.time_to_live &&
      delay_while_idle == that.delay_while_idle &&
      identity == that.identity
    end

  end
end
