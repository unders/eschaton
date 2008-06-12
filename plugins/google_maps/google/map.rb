module Google
  
  # Represents a google map. 
  #
  # See more online[http://code.google.com/apis/maps/documentation/reference.html#GMap2]
  class Map < MapObject
    attr_reader :center
    Control_types = [:small_map, :large_map, :small_zoom, 
                     :scale, 
                     :map_type, :menu_map_type, :hierarchical_map_type,
                     :overview_map]
    
    # :center, :controls
    def initialize(options = {})
      options.default! :var => 'map'
      
      super
            
      options.assert_valid_keys :center, :controls

      if self.create_var?
        script << "#{self.var} = new GMap2(document.getElementById('#{self.var}'));" 
    
        self.center = options[:center] if options[:center]
        self.add_control(options[:controls]) if options[:controls]
      end
    end
    
    # Centers the map at the given +location+
    # TODO - Handle optional arguments with javascript methods
    def center=(location)
      zoom = 12
      location = location.to_location if location.is_a?(Hash)
      
      @center = location
      script << "#{self.var}.setCenter(#{location}, #{zoom});"
    end
    
    def center
      @center
    end
    
    # Adds a control or controls to the map
    #   add_control :small_zoom, :map_type
    def add_control(*types)
      types.flatten.each do |type|
        google_control = "G#{type.to_s.classify}Control"
        script << "#{self.var}.addControl(new #{google_control}());"
      end
    end
    
    # Adds a marker to the map, +marker+ is either a Marker of marker options
    def add_marker(marker_or_options)
      marker_or_options = Marker.new(marker_or_options) if marker_or_options.is_options_hash?
      
      return_script do |script|
        script << marker_or_options
        script << "#{self.var}.addOverlay(marker);"
      end
    end
    
    # Attaches the given +block+ results to the "click" event of the map.
    # This will only run if the map is clicked, not an info window.
    def click(&block)      
      arguments = [:overlay, :location]
      # If there is no location, it means the actual map wasn't clicked.
      body = "if(location){
               #{yield(*arguments)}
              }
             "
      self.listen_to :click, :with => arguments, :on => self.var, 
                             :body => body
    end
    
    # Opens a information window on the map at the location supplied by +at+. Either a +url+ or +content+ option
    # can be supplied to place within the info window.
    #
    # :at::      => Required. A hash representing the location or a Location object where the info window must be placed.
    # :url::     => Optional. URL is generated by rails #url_for. Supports standard url arguments and javascript variable interpolation.
    # :content:: => Optional. The html content that will be placed inside the info window. 
    def open_info_window(options)
      options.assert_valid_keys :at, :url, :content
      
      at = options[:at]
      at = at.to_location if at.is_a?(Hash)
      
      if options[:url]      
        url = EschatonGlobal.current_controller.url_for(options[:url]).to_s
        parse_url_for_javascript url
      
        %{
          jQuery.get('#{url}', function(data) {          
            #{self.var}.openInfoWindow(#{at}, data);
          });
        }
      else
        "#{self.var}.openInfoWindow(#{at}, #{options[:content]});"
      end
    end
    
    def close_info_window
      script << "#{self.var}.closeInfoWindow();"
    end
      
  end
end