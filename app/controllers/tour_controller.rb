#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TourController < ApplicationController
  def vancouver
    @addresses = current_account.parties.find_addresses_with_pictures_on_tour
    render :layout => false, :content_type => 'application/xml; charset=UTF-8'
  end

  def details
    @address = current_account.addresses.find(params[:id])
    @party = @address.routable
    @invoice = @party.invoices.first rescue nil
    @categories = Configuration.find_all_by_group_name('estimates.categories').map {|conf| conf.product_category}

    return unless @invoice

    @lines = @invoice.lines.select {|itm| itm.product?}
    @lines.reject! {|itm| itm.product.name =~ /extension|power cable/i}
    @final = {}
    @lines.each do |itm|
      @final[itm.product.id] ||= [itm.product, 0]
      @final[itm.product.id][1] += itm.quantity
    end
    @lines = @final.values
  end
end
