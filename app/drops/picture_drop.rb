#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PictureDrop < Liquid::Drop
  attr_reader :picture

  def initialize(picture)
    @picture = picture
  end

  def thumbnail_url
    "/pictures/#{self.picture.id}/thumbnail.jpg"
  end

  def full_size_url
    "/pictures/zoom/#{self.picture.id}/image.jpg"
  end

  def as_link
    %Q(<a href="#{full_size_url}"><img src="#{thumbnail_url}"/></a>)
  end
end
