#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class String
  def as_absolute_url(host, options={})
    return self if self.blank? || URI.parse(self).absolute?
    options[:protocol] = "http" if options[:protocol].blank?
    options[:ssl?] = false if options[:ssl?].blank?
    host_plus_self = host + "/" + self
    host_plus_self.gsub!(/(\/)+/, "/")
    %Q~#{options[:protocol]}#{options[:ssl?] ? 's' : nil}://#{host_plus_self}~
  end
  
  # Converts a post title to its-title-using-dashes
  # All special chars are stripped in the process  
  def to_url
    returning(self.downcase) do |result|
      # replace quotes by nothing
      result.gsub!(/['"]/, '')
  
      # strip all non word chars
      result.gsub!(/[^A-Za-z0-9_\-]/i, ' ')
  
      # replace all white space sections with a dash
      result.gsub!(/\s+/, '-')
  
      # trim dashes
      result.gsub!(/(-)$/, '')
      result.gsub!(/^(-)/, '')
    end
  end
  
  def append_affiliate_username(username)
    return self if username.blank?
    if self.include?("?")
      t_input = self
      t_input = t_input.split("?").last.split("&")
      index = nil
      t_input.each_with_index do |e, i|
        index = i if e =~ /^pal=/i
      end
      if index
        t_input[index] = "pal=#{username}"
      else
        t_input << "pal=#{username}"
      end
      return self.split("?").first + "?" + t_input.join("&")
    else
      return self + "?pal=" + username
    end
  end
end
