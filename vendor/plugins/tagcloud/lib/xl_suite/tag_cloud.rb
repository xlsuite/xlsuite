module XlSuite
  module TagCloud
    # * <tt>:limit</tt>: The maximum number of tags to show.  The default is 20.
    # * <tt>:order</tt>: In what order should the tags be shown.  Accepts
    #                    <tt>:popularity</tt> or <tt>:alpha</tt>.  The default is
    #                    <tt>:popularity</tt>.
    # * <tt>:target_class</tt>: Optional.  If the object is nil, this value becomes
    #                           required.  This option identifies which class we
    #                           should query to find the tags to use.
    # * <tt>:field_id</tt>: The field to modify (add/remove tag name).
    def tag_cloud(object, method, options={})
      obj = instance_variable_get("@#{object}")
      obj_class = obj ? obj.class : options[:target_class].to_s.classify.constantize

      options.reverse_merge!(:field_id => "#{object}_#{method}", :obj_class => obj_class)
      content_tag(:div, tag_group(options),
          :class => 'tag_cloud', :id => "#{options[:field_id]}_tag_cloud")
    end

    # Generates an anchor tag that calls the +updateTagsField+ JavaScript
    # function.  See #tag_cloud for the required and optional options.
    def tag_group(options={})
      options.reverse_merge!(:order => :popularity, :limit => 20)
      order = case options[:order].to_s
              when 'popularity'
                'count DESC'
              when 'alpha'
                'LOWER(tags.name)'
              else
                raise ArgumentError, "Unknown order option for #tag_group: #{options[:order].inspect}; expected popularity or alpha"
              end

      obj_class = options[:obj_class] || options[:target_class].to_s.classify.constantize
      tags = obj_class.tags(:order => order)[0, options[:limit]]
      tags.map do |tag|
        link_to_function(h(tag.name), "updateTagsField('#{options[:field_id]}', '#{tag.name}')")
      end.join("\n")
    end
  end
end
