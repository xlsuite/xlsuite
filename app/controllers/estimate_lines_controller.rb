#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EstimateLinesController < ApplicationController
  required_permissions :edit_estimates

  before_filter :load_estimate
  before_filter :load_estimate_line, :only => %w(show edit update destroy)

  helper EstimatesHelper

  def index
    @estimate_lines = @estimate.lines
    @estimate_lines_count = @estimate_lines.length

    respond_to do |format|
      format.html
      format.js do
        render(:json => {:total => @estimate_lines_count, :collection => assemble_records(@estimate_lines)}.to_json)
      end
    end
  end

  def new
    @estimate_line = @estimate.lines.build
  end

  def create
    @estimate_line = EstimateLine.new(params[:estimate_line].merge!(:account_id => current_account.id))
    @estimate_line.estimate = @estimate

    if @estimate_line.save then
      flash_success :now, "Estimate line successfully created"
    else
      flash_failure :now, @estimate_line.errors.full_messages
    end

    respond_to do |format|
      format.js { render :json => json_response_for(@estimate_line).to_json }
    end
  end

  def edit
    render
  end

  def update
    @old_subtotal = @estimate.subtotal_amount
    @old_total = @estimate.total_amount

    if @estimate_line.update_attributes(params[:estimate_line]) then
      flash_success :now, "Estimate line successfully updated"
    else
      flash_failure :now, @estimate_line.errors.full_messages
    end

    respond_to do |format|
      format.html
      format.js { render :json => json_response_for(@estimate_line).to_json }
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    current_account.estimate_lines.find(params[:ids].split(",").map(&:strip)).to_a.each do |estimate_line|
      logger.debug("^^^#{estimate_line.inspect}")
      @destroyed_items_size += 1 if estimate_line.destroy
    end
    flash_success :now, "#{@destroyed_items_size} estimate line(s) successfully deleted"
    load_estimate
    respond_to do |format|
      format.js
    end
  end
  
  def reposition_lines
    ids = params[:ids].split(",").map(&:strip).to_a
    positions = params[:positions].split(",").map(&:strip).map(&:to_i).to_a
    EstimateLine.transaction do
      (0..ids.length-1).each do |i|
        @estimate.lines.find(ids[i]).update_attribute(:position, positions[i]+1)
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
    json_response = assemble_record(@estimate_line)
    json_response.merge!(:subtotal => @estimate.subtotal_amount.to_s) if @old_subtotal != @estimate.subtotal_amount
    json_response.merge!(:total => @estimate.total_amount.to_s) if @old_total != @estimate.total_amount
    json_response
  end

  protected
  def load_estimate
    @estimate = current_account.estimates.find(params[:estimate_id])
  end
  
  def load_estimate_line
    @estimate_line = @estimate.lines.find(params[:id])
  end
end
