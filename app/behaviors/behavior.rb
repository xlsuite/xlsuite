#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Behavior
  cattr_accessor :logger
  attr_reader :page, :parsed_template

  def initialize(page, parsed_template)
    @page, @parsed_template = page, parsed_template
  end

  def deserialize
  end

  def serialize(params)
  end

  def render_edit
    {:partial => template_path(self.class.name.underscore.gsub("_behavior", ""), :relative => true)}
  end

  def render(context)
  end

  def logger
    @@logger ||= RAILS_DEFAULT_LOGGER
  end

  def parse_template(template)
    Liquid::Template.parse(template)
  end

  def template_for(template)
    @parsed_template ||= self.parse_template(template)
  end

  protected
  def template_path(file, options={})
    if options[:relative] then
      File.join("..", "behaviors", file)
    else
      File.join(File.dirname(__FILE__), file)
    end
  end
end
