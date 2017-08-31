module Exceptions
  class PushmeupException < StandardError
    def initialize(message)
      super(message)
    end
  end
end