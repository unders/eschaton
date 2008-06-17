module Google
  
  class MapObject < JavascriptObject
    
    def initialize(options)
      super
    end
  
    # Listens for events on the client.
    # 
    # :event:: => Required. The event that should be listened to.
    # :on::  => Optional. The object on which the event occurs, defaulted to +JavascriptObject#var+
    # :with::  => Optional. Arguments that are passed along when the event is fired, these will also be yielded to the supplied block.
    #
    # A JavascriptGenerator along with the +with+ option will be yielded to the block.
    #
    #   map.listen_to :event => :click, :with => [:overlay, :within] do |script, overlay, location|
    #     script.alert('hello')
    #     map.open_info_window(:at => location, :content => 'A window is open!')
    #     # other code that will occur when this event happens...
    #   end
    def listen_to(options = {})
      options.default! :on => self.var, :with => []            
      options.assert_valid_keys :event, :on, :with
      
      with_arguments = options[:with]
      js_arguments = with_arguments.join(', ')
      self.script << "GEvent.addListener(#{options[:on]}, \"#{options[:event]}\", function(#{js_arguments}) {"

      self.as_global_script do
        yield *(self.script.arify + with_arguments)
      end

      self.script <<  "});"
    end

    # TODO - Make pretty and move to appropriate place
    def parse_url_for_javascript(url)
      interpolate_symbol, brackets = '%23', '%28%29'
      url.scan(/#{interpolate_symbol}[\w\.#{brackets}]+/).each do |javascript_variable|
        clean = javascript_variable.gsub(interpolate_symbol, '')
        clean.gsub!(brackets, '()')

        url.gsub!(javascript_variable, "' + #{clean} + '")
      end  
      
      url.gsub!('&amp;', '&')
      
      url
    end
    
    protected
      def options_to_fields(options)
        options.each do |key, value|
          method = "#{key}="
          self.send(method, value) if self.respond_to?(method)
        end
      end
  end
  
end

