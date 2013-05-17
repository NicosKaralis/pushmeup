module MPNS
  class Notification
    attr_accessor :device_url, :title, :message, :data
    
    def initialize(device_url, title, message = '', data = {}, options = {})
      self.device_url = device_url
      self.title = title
      self.message = message
      self.data = data
    end
  
    def packaged_message
      data_params = ''
      self.data.each_pair do |key, value|
        data_params += "<wp:#{key.capitalize}>#{value}</wp:#{key.capitalize}>"
      end
      "<?xml version='1.0' encoding='utf-8'?><wp:Notification xmlns:wp='WPNotification'><wp:#{@target.capitalize}><wp:Text1>#{self.title}</wp:Text1><wp:Text2>#{self.message}</wp:Text2>#{data_params}</wp:#{@target.capitalize}></wp:Notification>"
    end
    
  end
end
