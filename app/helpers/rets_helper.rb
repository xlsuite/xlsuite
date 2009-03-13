#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module RetsHelper
  def listing_pictures(listing, retriever)
    if listing.pictures.empty? then
      render(:partial => "rets/none", :locals => {:listing => listing, :retriever => retriever})
    else
      @id = listing.external_id
      render(:partial => "rets/thumbnails", :object => listing.pictures)
    end
  end
end
