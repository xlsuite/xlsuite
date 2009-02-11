module XlSuite #:nodoc:
  # Modifies the base +link_to+, +link_to_remote+ and +link_to_function+ methods
  # to add an icon.  The methods are called as usual, except they can now
  # sport a new option: <tt>:icon</tt>.
  #
  #  link_to('Home', :action => :index, :icon => :house)
  #    #=> <a href="/"><img src="/images/icons/house.png"/> Home</a>
  #
  #  link_to('Home', home_url, :icon => :house)
  #    #=> <a href="/"><img src="/images/icons/house.png"/> Home</a>
  #
  # It is also possible to put the icon at the back instead of the front
  # by using an options +Hash+ instead of the icon's name:
  #  link_to('Next Page', contacts_url(:page => 2), :icon => {:position => :back, :name => :resultset_next})
  #    #=> <a href="/contacts?page=2">Next Page <img src="/images/icons/resultset_next.png"/></a>
  #
  # The methods that this module makes available are also available as regular
  # helpers to call as you see fit.
  module LinkWithIcon
    def self.included(base) #:nodoc:
      base.class_eval do
        alias_method_chain :link_to, :icon
        alias_method_chain :link_to_remote, :icon
        alias_method_chain :link_to_function, :icon
      end
    end

    def link_to_with_icon(*args) #:nodoc:
      link_to_without_icon(*convert(*args))
    end

    def link_to_remote_with_icon(*args) #:nodoc:
      link_to_remote_without_icon(*convert(*args))
    end

    def link_to_function_with_icon(*args) #:nodoc:
      link_to_function_without_icon(*convert(*args))
    end

    # Returns an +IMG+ tag ready for use.  The +icon+ parameter is the name
    # of the icon, while the +text+ parameter will be used as the image's
    # +title+ and +alt+ attributes.
    #
    # The +text+ parameter is optional.
    # The last parameter of this method can be a Hash to set specific options.
    #
    # == Examples
    #
    #  icon_tag(:map)
    #    #=> <img src="icons/map.png" width="16" height="16" class="icon"/>
    #  icon_tag(:map, :class => "fancy")
    #    #=> <img src="icons/map.png" class="fancy icon" width="16" height="16"/>
    #  icon_tag("group.gif", "List of groups", :alt => "List of groups used in place")
    #    #=> <img src="icons/group.gif" alt="List of groups used in place"
    #             class="icon" title="List of groups" width="16" height="16"/>
    def icon_tag(icon, *args)
      return nil if icon.blank?
      options = args.last.kind_of?(Hash) ? args.pop : Hash.new
      text = args.last
      options[:class] = ((options[:class] || "") + " icon").strip
      image_tag("#{icon_path(icon)}", options.reverse_merge(:size => '16x16',
          :alt => text, :title => text))
    end

    # Returns the path to the icon named +icon+.  By default, we look in
    # <tt>icons/</tt>.
    def icon_path(icon)
      "icons/#{icon_name(icon)}"
    end

    # Returns the full name of the icon.  Icons have a +.png+ extension by
    # default.
    def icon_name(icon)
      icon = icon.to_s
      icon['.png'] ? icon : "#{icon}.png"
    end

    private
    def convert(*args) #:nodoc:
      icon = nil
      args.reverse.each do |options|
        break unless options.kind_of?(Hash)
        icon = options.delete(:icon)
        break unless icon.blank?
      end

      return args if icon.blank?

      case icon
      when Hash
        icon_text = icon_tag(icon[:name], args[0])
        icon_position = icon[:position]
      else
        icon_text = icon_tag(icon, args[0])
        icon_position = :front
      end

      returning args do
        args[0] = case icon_position.to_s
                  when 'front'
                    "#{icon_text} #{args[0]}"
                  when 'back'
                    "#{args[0]} #{icon_text}"
                  else
                    raise ArgumentError, "Unexpected #{icon_position.inspect}, expected either :front or :back"
                  end
      end
    end
  end
end
