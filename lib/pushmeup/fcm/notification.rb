module FCM

  class Notification
    attr_accessor :registration_ids, :data, :collapse_key, :time_to_live, :delay_while_idle, :identity, :condition

    def initialize(registration_ids, data, options = {})
      self.registration_ids = registration_ids
      self.data = data

      @collapse_key = options[:collapse_key]
      @time_to_live = options[:time_to_live]
      @delay_while_idle = options[:delay_while_idle]
      @identity = options[:identity]
      @condition = options[:conditions]
    end

    def registration_ids=(registration_ids)
      if registration_ids.is_a?(Array)
        @registration_ids = registration_ids
      elsif registration_ids.is_a?(String)
        @registration_ids = [registration_ids]
      else
        raise "registration_ids needs to be either an Array or String"
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

    def data_present?
      self.data and !self.data.empty?
    end

    def get_options
      options = {}
      options[:delay_while_idle] = self.delay_while_idle if self.delay_while_idle
      options[:time_to_live] = self.time_to_live if self.time_to_live
      options[:collapse_key] = self.collapse_key if self.collapse_key
      options[:identity] = self.identity if self.identity
      options[:data] = self.data if self.data_present?
      options
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