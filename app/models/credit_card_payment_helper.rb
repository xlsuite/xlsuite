#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CreditCardPaymentHelper < PaymentHelper
  # DOES NOT HAVE FREE TRIAL ON ACCOUNT MODULE SUBSCRIPTION
  def start!(payable, who, options={})
    payable.transaction do
      super
      raise ArgumentError, 'Payment must have been saved previously - we use the payment\'s ID in the request' if payable.payment.new_record?
      if options[:credit_card]
        credit_card = ActiveMerchant::Billing::CreditCard.new(options[:credit_card])
        credit_card.number = credit_card.number.gsub(/[^\d]/i, "")
        unless credit_card.valid?
          raise(StandardError, "Invalid credit card information: #{credit_card.errors.full_messages.join(', ')}")       
        end
      end
      gateway = ActiveMerchant::Billing::ExactGateway.new({:login => payable.account.get_config(:payment_gateway_username), :password => payable.account.get_config(:payment_gateway_password)})
      payment_amount_cents = 0
      response = nil
      subscription = false
      payable_subject = payable.subject
      case payable_subject
      when AccountModuleSubscription
        payment_amount_cents = payable_subject.initial_fee.cents
        raise(StandardError, "Payment amount to be charged cannot be zero") if payment_amount_cents == 0
        response = gateway.subscribe(payment_amount_cents, credit_card)
        subscription = true
      when Order
        payment_amount_cents = payable.subject.total_amount.cents  
        if payable_subject.subscription?
          response = gateway.subscribe(payment_amount_cents, credit_card)
          subscription = true
        else
          response = gateway.authorize(payment_amount_cents, credit_card)
        end
      when Subscription
        response = gateway.pay_subscription(payable.amount.cents, payable_subject.authorization_code)
        subscription = true
      else
        raise(StandardError, "response is nil payable subject not supported")
      end
      
      if response.success?
        options.merge!(:gateway => gateway, :response => response, :payment_cents => payment_amount_cents, :subscription => subscription)
        payable.payment.complete!(who, options)
      else
        raise(StandardError, response.message)
      end
    end
  end
  
  def complete!(payable, who, options={})
    payable.transaction do
      raise(StandardError, "Options need to contain gateway, response, payment_cents") unless options[:gateway] && options[:response] && options[:payment_cents]
      super
      gateway = options[:gateway]
      response = options[:response]
      payment_cents = options[:payment_cents].to_i
      if options[:subscription]
        case payable.subject
        when Subscription
          # NOP
        when Order
          subscription = payable.subject.account.subscriptions.create!(
            :next_renewal_at => payable.subject.subscription_next_renewal_at,
            :renewal_period => payable.subject.subscription_product.pay_period,
            :payer => who,
            :authorization_code => response.authorization,
            :payment_method => "credit_card",
            :subject => payable.subject
          )
        when AccountModuleSubscription
          master_account = Account.find_by_master(true)
          subscription = master_account.subscriptions.create!(
            :next_renewal_at => Time.now.utc + 1.month.to_i,
            :renewal_period => "1 month",
            :payer => who,
            :authorization_code => response.authorization,
            :payment_method => "credit_card",
            :subject => payable.subject
          )
        else
          raise "Payable subject not supported"
        end
      else
        gateway.capture(payment_cents, response.authorization)
      end
    end
  end
end
