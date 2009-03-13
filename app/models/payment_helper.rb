#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentHelper
  # Starts the payment against the remote entity, if one is required.
  # This method changes the payment's status to +started+.
  #
  # Subclasses must return a URL to which to redirect, or +nil+ if none is
  # known.
  #
  # This method expects the following symbol keys in +options+:
  #   * +return_url+: The URL to which the payment processor will return upon successful payment processing.
  #   * +cancel_url+: The URL to which the payment processor will return if the user elects to cancel payment.
  #   * +notify_url+: The URL to which the payment processor will send payment notification data.
  def start!(payable, who, options={})
    ActiveRecord::Base.transaction do
      raise XlSuite::PaymentSystem::HasBeenPaidInFull, "Has been paid in full" if payable.subject && payable.subject.paid_in_full?
      
      payment = payable.payment
      payment.save! if payment.new_record?
      payable.save! if payable.new_record?
      returning nil do
        if options[:amount]
          payable.amount = options[:amount]
          payable.save
        end
        if options[:description]
          payment.description = options[:description]
          payment.save
        end
        payment.transitions.create!(:action => "start", :from_state => payment.state, :to_state => "pending", :creator => who, :account => payment.account)
      end
    end
  end

  # Flags this payment as having been received.
  def receive!(payable, who, options={})
    payment = payable.payment
    from_state = payment.state
    payment.authorize_payment!
    payment.transitions.create!(:action => "receive", :from_state => from_state, :to_state => payment.state, :creator => who, :account => payment.account)
  end

  # Completes this payment.  Upon completion, this payment's status will be
  # paid, and the external reference number of the latest PaymentTransition will have been set.
  #
  # This method returns no meaningful value.
  def complete!(payable, who, options={})
    ActiveRecord::Base.transaction do
      payment = payable.payment
      from_state = payment.state
      %w(domain login_url reset_password_url subject_url).each do |option_key|
        payment.send(option_key+"=", options[option_key.to_sym])
      end
      payment.capture_payment!
      payment.transitions.create!(:action => "complete", :from_state => from_state, :to_state => payment.state, :creator => who, 
        :account => payment.account, 
        :external_reference_number => options[:external_reference_number],
        :response_data => options[:response_data],
        :ipn_request_headers => options[:ipn_request_headers],
        :ipn_request_parameters => options[:ipn_request_parameters])

      # Ensure the payable's subject (order, invoice, etc) is notified of the fact that a payment was made
      payable.subject.reload.save!
    end
  end

  # Cancels this payment.
  def cancel!(payable, who, options={})
    payment = payable.payment
    from_state = payment.state
    payment.cancel_payment!
    payment.transitions.create!(:action => "cancel", :from_state => from_state, :to_state => payment.state, :creator => who, :account => payment.account)
  end
  
  # Decline this payment
  def decline!(payable, who, options={})
    payment = payable.payment
    from_state = payment.state
    payment.decline_payment!
    payment.transitions.create!(:action => "decline", :from_state => from_state, :to_state => payment.state, :creator => who, :account => payment.account)
  end  
end
