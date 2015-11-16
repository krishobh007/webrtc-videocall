module Socky
  module Server
    class Connection
      include Misc
    
      attr_accessor :id, :application
    
      # initialize new connection
      # @param [Socky::Server::WebSocket] socket websocket connection
      # @param [String] app_name connection application name
      def initialize(socket, app_name)
        @socket = socket
        @application = Application.find(app_name)
      
        unless @application.nil?
          @id = self.generate_id
          @application.add_connection(self)
        end
        @client = Client.new do |u|
          u.client_id = @id
          u.client_email = "client_email"
        end
        @client.save
        #self.send_data(initialization_status)
        @socket.close_websocket if @application.nil?
      end
    
      # return info about connection initialization
      # if successfull then it will return hash with connection id
      # otherwise it will return reson why connecton has failed
      def initialization_status
        if @application && @id
          { 'event' => 'socky:connection:established', 'connection_id' => @id }
        else
          { 'event' => 'socky:connection:error', 'reason' => 'refused' }
        end
      end
    
      # list of channels connection is subscribed to
      def channels
        @channels ||= {}
      end
    
      # send data to connection
      # @param [String] data data to send
      def send_data(data)
        @socket.send_data(data)
      end
    
      # remove connection from application
      def destroy
        log('connection closing', @id)
        if @application
          @application.remove_connection(self)
          @application = nil
          @client.destroy
        end
        self.channels.values.each do |channel|
          channel.remove_subscriber(self)
        end
      end
    
      # generate new id
      # @return [String] connection id
      def generate_id
        @id = Time.now.to_f.to_s.gsub('.', '')
      end
    
    end
  end
end
