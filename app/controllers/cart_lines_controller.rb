#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartLinesController < ApplicationController
  skip_before_filter :login_required
  
  before_filter :load_cart
  before_filter :create_cart
  before_filter :load_cart_line, :only => [:update, :destroy]
  
  def create
    @cart_line = @cart.add_product(params[:cart_line])
    logger.info("Failed creating a cart line #{@cart_line.errors.full_messages}") unless @cart_line.save
    flash_success "#{@cart_line.quantity} #{@cart_line.product.name} added to your shopping cart"
    redirect_to_return_to_or_back
  end
  
  def update
    if params[:cart_line][:quantity].to_i <= 0
      @cart_line.destroy
      flash_success "#{@cart_line.product.name} was removed from your cart"
    else
      @cart_line.attributes = params[:cart_line]
      logger.info("Failed updating a cart line #{@cart_line.errors.full_messages}") unless @cart_line.save
    end
    redirect_to_return_to_or_back
  end
  
  def destroy
    @cart_line.destroy
    flash_success "#{@cart_line.product.name} was removed from your cart"
    redirect_to_return_to_or_back
  end
  
  def destroy_collection
    params[:ids].split(",").map(&:strip).each do |id|
      cl = @cart.lines.find(id)
      cl.destroy
    end
    redirect_to_return_to_or_back
  end
  
  protected
  
  def load_cart_line
    @cart_line = @cart.lines.find(params[:id])
  end
end
