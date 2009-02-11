module DomId

  VERSION='0.1.0'

  ##
  # Implementation of http://codefluency.com/articles/2006/05/30/rails-views-dom-id-scheme
  #
  #  comment.dom_id
  #  => "comment_15"
  #
  # Use in views and controllers instead of doing "comment_<%= comment.id %>"
  #
  # 
  def dom_id(prefix=nil)
    display_id = new_record? ? "new" : id
    prefix = prefix.nil? ? self.class.name.underscore : "#{prefix}_#{self.class.name.underscore}"
    "#{prefix}_#{display_id}"
  end

end
