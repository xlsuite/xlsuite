module FrancoisBeausoleil #:nodoc
  module FlashHelperPlugin #:nodoc
    module ApplicationHelper
      # Generates an HTML div that will show all available messages from the Flash.
      # The default keys that will be shown are:
      # * :warning
      # * :notice
      # * :message
      # in this order.
      #
      # Valid options are:
      # * <tt>:keys</tt> Selects which, and in which order, Flash keys will be output.  By default, this is equal to
      #   <tt>[:warning, :notice, :message]</tt>
      # * <tt>:textilize</tt> Determines if Textile / RedCloth markup should be used to format the messages.  This must
      #   be <tt>true</tt> or <tt>false</tt>, with <tt>false</tt> being the default value.
      # * <tt>:id</tt> Selects the ID attribute of the DIV into which the messages will be output.  By default, this
      #   is equal to <tt>messages</tt>.  Use the <tt>false</tt> value to disable this behavior.
      #
      # === Examples
      # Assume the flash's content (YAML) is:
      #  ---
      #  :warning:
      #    - Tax application was rejected for user 42
      #  :message:
      #    - Server will shutdown in *42* minutes
      #    - No applications will be accepted beyond that date.
      #  :notice:
      #    - Update successful
      #
      #  <%= show_flash_messages %>
      #  <div id="messages">
      #    <ul id="warnings">
      #      <li class="warning">Tax application was rejected for user 42</li>
      #    </ul>
      #    <ul id="messages">
      #      <li class="message">Server will shutdown in *42* minutes</li>
      #      <li class="message">No applications will be accepted beyond that date.</li>
      #    </ul>
      #    <ul id="notices">
      #      <li class="notice">Update successful</li>
      #    </ul>
      #  </div>
      #
      #  <%= show_flash_messages(:keys => [:notice, :warning]) %>
      #  <div id="messages">
      #    <ul id="warnings">
      #      <li class="warning">Tax application was rejected for user 42</li>
      #    </ul>
      #    <ul id="notices">
      #      <li class="notice">Update successful</li>
      #    </ul>
      #  </div>
      #
      #  <%= show_flash_messages(:id => 'user-message-area') %>
      #  <div id="user-message-area">
      #    <ul id="warnings">
      #      <li class="warning">Tax application was rejected for user 42</li>
      #    </ul>
      #    <ul id="messages">
      #      <li class="message">Server will shutdown in *42* minutes</li>
      #      <li class="message">No applications will be accepted beyond that date.</li>
      #    </ul>
      #    <ul id="notices">
      #      <li class="notice">Update successful</li>
      #    </ul>
      #  </div>
      #
      #  <%= show_flash_messages(:textilize => true) %>
      #  <div id="messages">
      #    <ul id="warnings">
      #      <li class="warning"><p>Tax application was rejected for user 42</p></li>
      #    </ul>
      #    <ul id="messages">
      #      <li class="message"><p>Server will shutdown in <strong>42</strong> minutes</p></li>
      #      <li class="message"><p>No applications will be accepted beyond that date.</p></li>
      #    </ul>
      #    <ul id="notices">
      #      <li class="notice"><p>Update successful</p></li>
      #    </ul>
      #  </div>
      def show_flash_messages(options={})
        options = { :keys => [:warning, :notice, :message],
                    :id => 'messages',
                    :textilize => false}.merge(options)
        out = []
        options[:keys].each do |key|
          next unless flash[key]
          messages = []
          [flash[key]].flatten.compact.each do |msg|
            text = (options[:textilize] ? textilize(msg) : msg)
            messages << content_tag('li', text, :class => key)
          end

          out << content_tag('ul', messages.join("\n"), :class => key.to_s.pluralize) unless messages.empty?
        end

        attrs = {:id => options[:id]} if options[:id]
        return nil if out.empty? 
        content_tag('div', out.join("\n"), attrs)
      end
    end
  end
end
