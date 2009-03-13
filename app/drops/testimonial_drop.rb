#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TestimonialDrop < Liquid::Drop
  attr_reader :testimonial
  delegate :id, :dom_id, :testified_at, :body, :author_company_name, :author_name, :phone_number, :email_address, :website_url, :author, :to => :testimonial

  def initialize(testimonial)
    @testimonial = testimonial
  end
  
  def avatar
    self.testimonial.show_avatar? ? self.testimonial.avatar : nil
  end
end
