#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentPlansController < ApplicationController
  required_permissions %w(index show new edit create update destroy) => [:edit_payment_plans]
  
  before_filter :load_payment_plan, :only => %w(show edit update destroy)
  
  def index
    @payment_plans = PaymentPlan.find(:all)
  end
  
  def show
    render :action => "edit"
  end
  
  def new
    @payment_plan = PaymentPlan.new
  end
  
  def edit
  end

  def create
    @payment_plan = PaymentPlan.new
    if @payment_plan.update_attributes(params[:payment_plan])
      flash_success "#{@payment_plan.name} payment plan successfully created"
      redirect_to payment_plans_path
    else
      flash_success "Creating new payment plan failed"    
      redirect_to payment_plans_path
    end
  end
  
  def update
    if @payment_plan.update_attributes(params[:payment_plan])
      flash_success "#{@payment_plan.name} payment plan successfully edited"
      redirect_to payment_plans_path
    else
      flash_success "#{@payment_plan.name} payment plan update failed"    
      redirect_to payment_plans_path
    end
  end
  
  def destroy
    name = @payment_plan.name
    if @payment_plan.destroy
      flash_success "#{name} payment plan successfully destroyed"
      redirect_to payment_plans_path
      return
    end
    flash_failure "Destroying #{name} payment plan failed"
    redirect_to payment_plans_path
  end
  
protected
  def load_payment_plan
    @payment_plan = PaymentPlan.find(params[:id])
  end
end
