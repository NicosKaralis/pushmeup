module GCM
  class Notification
    attr_accessor :device_tokens, :data, :collapse_key, :time_to_live, :delay_while_idle, :identifier

    def initialize(device_tokens, data, options = {})
      self.device_tokens = device_tokens
      self.data = data

      @collapse_key = options[:collapse_key]
      @time_to_live = options[:time_to_live]
      @delay_while_idle = options[:delay_while_idle]
      @identifier = options[:identifier]
    end

    def device_tokens=(device_tokens)
      if device_tokens.is_a?(Array)
        @device_tokens = device_tokens
      elsif device_tokens.is_a?(String)
        @device_tokens = [device_tokens]
      else
        raise Exceptions::PushmeupException.new('Device tokens must be an Array or String')
      end
    end

    def data=(data)
      if data.is_a?(Hash)
        @data = data
      else
        raise Exceptions::PushmeupException.new('Data must be a Hash')
      end
    end

    def delay_while_idle=(delay_while_idle)
      @delay_while_idle = (delay_while_idle == true || delay_while_idle == :true)
    end

    def time_to_live=(time_to_live)
      if time_to_live.is_a?(Integer)
        @time_to_live = time_to_live
      else
        raise Exceptions::PushmeupException.new('Time to live must be an Integer')
      end
    end

    def ==(that)
      device_tokens == that.device_tokens &&
      data == that.data &&
      collapse_key == that.collapse_key &&
      time_to_live == that.time_to_live &&
      delay_while_idle == that.delay_while_idle &&
      identifier == that.identifier
    end
  end
end
