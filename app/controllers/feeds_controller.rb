#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FeedsController < ApplicationController
  required_permissions %w(index new create edit update destroy refresh refresh_all\
                          refresh_my_feeds auto_complete_tag) => :edit_feeds,
                        %w(show_feeds) => true
  before_filter :load_feed, :except => %w(refresh_my_feeds show_feeds index new create auto_complete_tag refresh_all)
  before_filter :load_common_tags, :only => %w(new edit)
  
  def show_feeds
    respond_to do |format|
      format.js
    end
  end
  
  def index
    @title = 'Listing feeds'
    
    items_per_page = params[:show] || ItemsPerPage
    items_per_page = current_account.feeds.count if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i

    @pager = ::Paginator.new(current_account.feeds.count, items_per_page) do |offset, per_page|
      current_account.feeds.find(:all, :limit => per_page, :offset => offset)
    end

    @page = @pager.page(params[:page])
    @feeds = @page.items
  end

  def new
    @feed = current_account.feeds.build
  end

  def create
    @feed = current_account.feeds.build(params[:feed])
    @feed.created_by = current_user
    if @feed.save then
      flash_success "Feed created"
      if params[:party]
        current_user.feeds<<@feed
      else
        current_user.feeds.delete(@feed)
      end
      redirect_to feeds_url
    else
      load_common_tags
      render(:action => :new)
    end
  end

  def edit
    render
  end

  def update
    if params[:party]
      current_user.feeds<<@feed
    else
      current_user.feeds.delete(@feed)
    end
    @feed.updated_by = current_user
    @feed.refresh_now = true
    if @feed.update_attributes(params[:feed]) then
      redirect_to feeds_url
    else
      render(:action => :new)
    end
  end

  def destroy
    if @feed.destroy then
      flash_success "Feed was successfully destroyed"
      redirect_to feeds_url
    else
      flash_failure :now, "Unable to destroy feed"
      render(:action => :new)
    end
  end

  def refresh
    @feed.refresh
    flash_success "Feed successfully refreshed"
    redirect_to feeds_url
  end
  
  def refresh_all
    current_account.feeds.map(&:refresh)
    flash_success "All feeds successfully refreshed"
    redirect_to feeds_url
  end
  
  def refresh_my_feeds
    current_user.feeds.find(:all).map(&:refresh)
    render(:action => :show_feeds)
  end

  def auto_complete_tag
    @tags = current_account.feeds.tags_like(params[:q])
    render_auto_complete(@tags)
  end

  protected
  def load_feed
    @feed = current_account.feeds.find(params[:id])
  end

  def load_common_tags
    @common_tags = current_account.feeds.tags(:order => "count DESC, name ASC")
  end
end
