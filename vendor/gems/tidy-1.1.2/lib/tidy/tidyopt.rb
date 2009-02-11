# Ruby interface to Tidylib options.
#
class Tidyopt

  # Construct a new instance.
  #
  def initialize(doc)
    @doc = doc
  end
    
  # Reader for options (Hash syntax).
  #
  def [](name)
    Tidylib.opt_get_value(@doc, name)
  end
    
  # Writer for options (Hash syntax).
  #
  def []=(name, value)
    Tidylib.opt_parse_value(@doc, name, value)
  end
    
  # Reader/Writer for options (Object syntax).
  #
  def method_missing(name, value=:none, *args)
    name = name.to_s.gsub('=', '')
    return self[name] if value == :none
    self[name] = value
  end

end
