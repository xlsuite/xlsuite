#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentsController < ApplicationController
  required_permissions :none

  before_filter :find_common_payments_tags, :only => [:new, :edit]
  before_filter :find_payment, :only => [:edit, :update, :destroy]
  before_filter :load_subject, :only => [:create]

  def index
    respond_to do |format|
      format.js
      format.json do
        process_index
        render(:json => {:total => @payments_count, :collection => assemble_records(@payments)}.to_json)
      end
    end
  end

  def new
    @payment = Payment.new
    respond_to do |format|
      format.js
    end
  end

  def create
    errors = ""
    begin
      ActiveRecord::Base.transaction do
        @payment = self.current_account.payments.build(params[:payment])
        @payment.payer = self.current_user
        @payment.save!
        payable = self.current_account.payables.build
        payable.payment = @payment
        payable.subject = @subject
        payable.amount_cents = @payment.amount_cents
        payable.amount_currency = @payment.amount_currency
        payable.created_by_id = self.current_user.id
        payable.updated_by_id = self.current_user.id
        payable.save!
        @created = true
      end
    rescue
      errors = $!.to_s
      @created = false
    end
    if @created
      flash_success :now, "Payment successfully created"
    else
      flash_failure :now, @payment.errors.full_messages
    end
    respond_to do |format|
      format.js do
        response = {:success => @created}
        if @created       
          response.merge!({
            :id => @payment.id,
            :object_id => @payment.dom_id,
            :amount => @payment.amount.to_s,
            :state => @payment.state,
            :payment_method => @payment.payment_method,
            :ever_failed => @payment.ever_failed,
            :created_at => @payment.created_at.strftime(DATE_STRFTIME_FORMAT),
            :updated_at => @payment.updated_at.strftime(DATE_STRFTIME_FORMAT)
          });
        else
          response.merge!(:errors => errors)
        end
        render(:json => response)
      end
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @payment.attributes = params[:payment]
    @updated = @payment.save
    if !@updated
      flash_failure :now, @payment.errors.full_messages
    end
    respond_to do |format|
      format.js do
        response = {:success => @updated}
        if @updated       
          response.merge!({
            :id => @payment.id,
            :object_id => @payment.dom_id,
            :amount => @payment.amount.to_s,
            :state => @payment.state,
            :payment_method => @payment.payment_method,
            :ever_failed => @payment.ever_failed,
            :created_at => @payment.created_at.strftime(DATE_STRFTIME_FORMAT),
            :updated_at => @payment.updated_at.strftime(DATE_STRFTIME_FORMAT)
          });
        else
          response.merge!(:errors => errors)
        end
        render(:json => response)
      end
    end
  end

  def tagged_collection
    @tagged_items_size = 0
    current_account.payments.find(params[:ids].split(",").map(&:strip)).to_a.each do |payment|
      next unless payment.writeable_by?(current_user)
      payment.tag_list = payment.tag_list + " #{params[:tag_list]}"
      @tagged_items_size += 1 if payment.save
    end

    respond_to do |format|
      format.js do
        flash_success :now, "#{@tagged_items_size} payments has been tagged with #{params[:tag_list]}"
      end
    end
  end

  protected
  
  def assemble_records(payments)
    out = []
    payments.each do |payment|
      out << {
        :id => payment.id,
        :object_id => payment.dom_id,
        :amount => payment.amount.to_s,
        :state => payment.state,
        :payment_method => payment.payment_method,
        :ever_failed => payment.ever_failed,
        :created_at => payment.created_at.strftime(DATE_STRFTIME_FORMAT),
        :updated_at => payment.updated_at.strftime(DATE_STRFTIME_FORMAT)
      }
    end
    out
  end
  
  def load_subject
    @subject = params[:subject_type].constantize.find(:first, :conditions => {:id => params[:subject_id], :account_id => self.current_account.id})
  end
  
  def load_payment
    @payment = self.current_account.payments.find(params[:id])
  end

  def find_common_payments_tags
    @common_tags = current_account.payments.tags(:order => "count DESC, name ASC")
  end

  def process_index
    if params[:subject_type] && params[:subject_id]
      @payments = params[:subject_type].constantize.find(params[:subject_id]).payments
      @payments_count = @payments.length
    else
      @payments = current_account.payments.find(:all)
      @payments_count = current_account.payments.count
    end
  end

  def find_payment
    @payment = current_account.payments.find(params[:id])
  end
end
