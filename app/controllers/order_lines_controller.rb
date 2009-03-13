#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class OrderLinesController < ApplicationController
  required_permissions :edit_orders

  before_filter :load_order
  before_filter :load_order_line, :only => %w(show edit update)

  helper OrdersHelper

  def index
    @order_lines = @order.lines
    @order_lines_count = @order_lines.length

    respond_to do |format|
      format.html
      format.js do
        render(:json => {:total => @order_lines_count, :collection => assemble_records(@order_lines)}.to_json)
      end
    end
  end

  def new
    @order_line = @order.lines.build
  end

  def create
    @order_line = OrderLine.new(params[:order_line].merge!(:account_id => current_account.id))
    @order_line.order = @order

    if @order_line.save then
      flash_success :now, "Order line successfully created"
    else
      flash_failure :now, @order_line.errors.full_messages
    end

    respond_to do |format|
      format.js { render :json => json_response_for(@order_line).to_json }
    end
  end

  def edit
    render
  end

  def update
    @old_subtotal = @order.subtotal_amount
    @old_total = @order.total_amount

    if @order_line.update_attributes(params[:order_line]) then
      flash_success :now, "Order line successfully updated"
    else
      flash_failure :now, @order_line.errors.full_messages
    end

    respond_to do |format|
      format.html
      format.js { render :json => json_response_for(@order_line).to_json }
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    @order.lines.find(params[:ids].split(",").map(&:strip)).to_a.each do |order_line|
      logger.debug("^^^#{order_line.inspect}")
      @destroyed_items_size += 1 if order_line.destroy
    end
    flash_success :now, "#{@destroyed_items_size} order line(s) successfully deleted"
    load_order
    respond_to do |format|
      format.js
    end
  end
  
  def reposition_lines
    ids = params[:ids].split(",").map(&:strip).to_a
    positions = params[:positions].split(",").map(&:strip).map(&:to_i).to_a
    OrderLine.transaction do
      (0..ids.length-1).each do |i|
        @order.lines.find(ids[i]).update_attribute(:position, positions[i]+1)
      end
    end
    render :nothing => true
  end

  protected
  def assemble_records(records)
    results = []
    records.each do |record|
      results << assemble_record(record)
    end
    results
  end
  
  def assemble_record(record)
    target = ""
    target_name = ""

    unless record.product.blank?
      target = record.product.dom_id
      target_name = record.product.name
    end
    result = {
      :id => record.id,
      :object_id => record.dom_id, 
      :quantity => record.quantity,
      :retail_price => record.retail_price.to_s, 
      :description => record.description, 
      :extension => (record.retail_price && record.quantity) ? record.extension_price.to_s : "",
      :target_id => target,
      :target_name => target_name
    }
    result
  end
  
  def json_response_for(record)
    json_response = assemble_record(@order_line)
    json_response.merge!(:subtotal => @order.subtotal_amount.to_s) if @old_subtotal != @order.subtotal_amount
    json_response.merge!(:total => @order.total_amount.to_s) if @old_total != @order.total_amount
    json_response
  end

  protected
  def load_order
    @order = current_account.orders.find(params[:order_id])
  end
  
  def load_order_line
    @order_line = @order.lines.find(params[:id])
  end
end
