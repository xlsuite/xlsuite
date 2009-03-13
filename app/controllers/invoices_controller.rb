#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InvoicesController < ApplicationController
  required_permissions :edit_invoices
  before_filter :load_invoice, :only => %w(edit update)

  def index
    @paginator = ::Paginator.new(current_account.invoices.count, 30) do |offset, limit|
      current_account.invoices.find(:all, :order => "number", :offset => offset, :limit => limit)
    end

    @page = @paginator.page(params[:page])
    @invoices = @page.items
  end

  def new
    @invoice = current_account.invoices.build
  end

  def create
    params[:invoice][:invoice_to] = current_account.parties.find(params[:invoice].delete(:invoice_to_id))
    @invoice = current_account.invoices.create!(params[:invoice])
  end

  def edit
    render
  end

  def update
    @invoice.update_attributes!(params[:invoice])
  end

  protected
  def load_invoice
    @invoice = current_account.invoices.find(params[:id])
  end
end
