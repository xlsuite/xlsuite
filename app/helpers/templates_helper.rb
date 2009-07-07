#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module TemplatesHelper

  TemplateSyntaxes = {
    "full_name" => "Company, last, first, middle names",
    "company_name" => "Company name",
    "name_only" => "Last, first names",
    "first_name" => "First name",
    "last_name" => "Last name", 
    "middle_name" => "Middle name", 
    "email" => "E-Mail address (also their login)",
    "login_info" => "You may login to your account at... Your username is... Get a new password by visiting...",
     
    "line1" => "", 
    "line2" => "",
    "city" => "",
    "state" => "Province or state (abbreviation)",
    "zip" => "Postal or zip code",
    "country" => "",
    
    "now" => "Today's date and time",
    "year" => "The year, at the time of sending the E-Mail",
    "month" => "The full month's number (at the time of sending the E-Mail)",
    "month_name" => "The full month's name (at the time of sending the E-Mail)",
    
    "randomize_password_if_none" => "Randomizes the recipient's password and pastes it into the body in the format 'Password: (new pw)'",
    
    "domain.name" => "Name of the selected domain",
    
    "recipient.profile.id" => "Recipient's profile ID"
    }.sort.freeze

  def render_template_syntaxes
    out = []
    out << "<ul>"
    TemplateSyntaxes.each do |key, desc|
      out << content_tag( :li, link_to_function("{{ #{key} }}", "insertToTemplateTargetField('{{ #{key} }}')") ) 
    end
    out << "</ul>"
    out
  end
  
  def render_plain_template_syntaxes
    out = []
    out << "<ul>"
    TemplateSyntaxes.each do |key, desc|
      out << content_tag( :li, "{{#{key}}}") 
    end
    out << "</ul>"
    out
  end
end
