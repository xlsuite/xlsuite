#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FuturesController < ApplicationController
  required_permissions %w(async_get_future_as_json show show_collection async_get_futures_as_json) => "current_user?"

  before_filter :select_refresh_interval
  before_filter :select_control_names

  def show
    @future = Future.find_by_account_id_and_owner_id_and_id(current_account, current_user, params[:id])
    @errors = [@future.results[:error]].compact
    do_response
  end

  def async_get_futures_as_json
    status = Future.get_status_of(params[:ids])
    render :json => status.to_json
  end

  def async_get_future_as_json
    future = Future.find_by_account_id_and_owner_id_and_id(current_account, current_user, params[:id])
    raise ActiveRecord::RecordNotFound unless future
    record = {
      'id' => future.id,
      'status' => future.status.humanize,
      'startedAt' => future.started_at,
      'progress' => future.progress,
      'returnTo' => future.return_to,
      'isCompleted' => future.done?,
      'results' => future.results,
      'errors' => [future.results[:error]].compact,
      'name' => future.class.name.underscore.gsub('future', '').humanize
    }
    render :json => record.to_json
  end
  
  def show_collection
    future_ids = params[:ids].map(&:strip)
    raise ActiveRecord::RecordNotFound if future_ids.blank?
    @futures = current_account.futures.find(future_ids, :order => "ended_at",
        :conditions => {:owner_id => current_user.id, :account_id => current_account.id})
    @errors = @futures.select(&:errored?).map {|f| f.results[:error]}.compact

    @future = Future.new
    @future.result_url = params[:return_to]
    @future.progress = (@futures.sum(&:progress) / future_ids.size.to_f).round.to_i
    @future.status = if @futures.all?(&:done?) then
      Future::COMPLETED_STATUS
    else
      "searching"
    end
    
    if @future.completed? && !@errors.blank?
      error_text = "#{@errors.size} "
      error_text << if @errors.size > 1 then "searches" else "search" end
      error_text << " failed"
      flash_failure error_text 
    end

    do_response
  end

  protected
  def control_name(name)
    if params.has_key?(name) then
      params[name].blank? ? nil : params[name]
    else
      name.to_s
    end
  end

  def select_refresh_interval
    @refresh_interval = (RAILS_ENV == "production" ? 2.seconds : 8.seconds)
  end

  def select_control_names
    @progress = control_name(:progress)
    @elapsed = control_name(:elapsed)
    @status = control_name(:status)
  end

  def do_response
    respond_to do |format|
      format.html do
        if @future.completed?
          return redirect_to(@future.return_to) if !@future.return_to.blank?
        end
        render :action => "show"
      end
      format.js do
        RAILS_DEFAULT_LOGGER.debug("^^^#{@errors.class.name} #{@errors.size}")
        RAILS_DEFAULT_LOGGER.debug("^^^#{@errors.inspect}")
        #render :action => 'show.rjs', :content_type => 'text/javascript; charset=utf-8', :layout => false 
      end
    end
  end
end
