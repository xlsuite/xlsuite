#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaypalPaymentHelper < PaymentHelper
  def start!(payable, who, options={})
    payable.transaction do
      super
      raise ArgumentError, 'Payable must have been saved previously - we use the payable\'s ID in the PayPal IPN request' if payable.new_record?

      @paypal_ipn_url   = Configuration.get(:paypal_payment_url)
      
      if payable.subject.kind_of?(AccountModuleSubscription)
        payable_subject = payable.subject
        @paypal_business = "riel@ixld.com"
        
        setup_fee = sprintf("%.2f", (payable_subject.subscription_fee.cents + payable_subject.setup_fee.cents) / 100.0)
        subscription_fee = sprintf("%.2f", payable_subject.subscription_fee.cents / 100.0)

        params = {
          :business => @paypal_business,
          :custom => payable_subject.uuid,
          :invoice => payable_subject.number,
          :currency_code => payable.amount.currency.upcase,
          :charset => 'utf-8',

          :no_shipping => '1',
          :no_note => '1',
          :tax => "0.00",
          :rm => '2',
          :return => options[:return],
          :cancel_return => options[:cancel_return],
          :notify_url => options[:notify_url]
        }

        params.merge!({
          :cmd => "_xclick-subscriptions",

          :item_number => payable_subject.number,
          #:amount => subscription,
          :quantity => '1',
          :item_name => payable_subject.payment.description,
          :a1 => setup_fee,
          :p1 => 1,
          :t1 => "M",
          :a3 => subscription_fee,
          :p3 => 1,
          :t3 => "M",
          :src => '1'
        })
      else
        @paypal_business  = payable.account.get_config(:paypal_business)
        
        order_or_invoice = payable.subject
        subscription_product = nil
        product_params = {}
        
        product_index = 0
        
        order_or_invoice.lines.each_with_index do |line, index|
          next unless line.retail_price
          product_line = line.product
          product_index = index + 1
          product_params.merge!({
            "item_name_#{product_index}" => product_line ? product_line.name : line.description,
            "amount_#{product_index}" => sprintf("%.2f", line.retail_price.cents / 100.0),
            "quantity_#{product_index}" => line.quantity.to_i
          })
          if product_line && product_line.pay_period
            subscription_product = product_line
          end
        end
        
        price = sprintf("%.2f", payable.amount.cents / 100.0)
        shipping_amount = sprintf("%.2f", order_or_invoice.shipping_fee.cents / 100.0)

        params = {
          :business => @paypal_business,
          :custom => payable.id,
          :invoice => order_or_invoice.number,
          :currency_code => payable.amount.currency.upcase,
          :charset => 'utf-8',

          :no_shipping => '1',
          :no_note => '1',
          :tax => "0.00",
          :rm => '2',

          :return => options[:return],
          :cancel_return => options[:cancel_return],
          :notify_url => options[:notify_url]
        }

        if subscription_product
          params.merge!({
            :cmd => "_xclick-subscriptions",

            :item_number => order_or_invoice.number,
            :amount => price,
            :quantity => '1',
            :item_name => subscription_product.name,
            :a3 => price,
            :p3 => subscription_product.pay_period.length,
            :t3 => subscription_product.pay_period.unit[0,1].upcase,
            :src => '1'
          })
          if subscription_product.free_period
            params.merge!({
              :a1 => 0,
              :p1 => subscription_product.free_period.length,
              :t1 => subscription_product.free_period.unit[0,1].upcase
            })
          end        
        else
          params.merge!({
            :cmd => "_cart",
            :upload => '1',
            :rm => '2',
            
            :quantity_1 => 1,
            :amount_1 => order_or_invoice.total_amount.cents / 100.0,
            :item_name_1 => "Payment for #{order_or_invoice.class.name.humanize} ##{order_or_invoice.number} at #{order_or_invoice.domain.name}"
          })
        end
      end

      raw_data = params.to_a.map {|k,v| "#{k.to_s}=#{CGI.escape(v.to_s)}"}.join('&')
      out = ["POSTing to PayPal at <#{@paypal_ipn_url}>"]
      out << "  #{raw_data}"
      params.to_a.sort_by{|a| a[0].to_s}.each do |k,v|
        out << "    #{k}  =  #{v}"
      end

      out << '--------------------------------------------------------'

      RAILS_DEFAULT_LOGGER.info out.join("\n")

      return "#{@paypal_ipn_url}?#{raw_data}"
    end
  end

  # TODO : talk with Francois about these items 
  # - i don't think the amount checking is right anymore
  # - what goes into response_message in PaymentTransition?
  def complete!(payable, who, options={})
    raw_post = options[:response_data]

    Paypal::Notification.ipn_url = payable.account.get_config(:paypal_payment_url)
    notify = Paypal::Notification.new(raw_post)
    raise SpoofingAttemptError, "PayPal IPN spoofing attempt - PayPal rejected transaction" if !notify.acknowledge

    payable.transaction do
      validation_passed = false
      payable_subject = payable.subject
      if payable_subject.kind_of?(AccountModuleSubscription)
        RAILS_DEFAULT_LOGGER.warn(%Q`
          payable_subject.number #{payable_subject.number} == #{notify.item_id} notify.item_id
        `)
        validation_passed = (payable_subject.number == notify.item_id)
        if notify.params["txn_type"] =~ /^subscr_signup$/i
          RAILS_DEFAULT_LOGGER.warn(%Q`
            notify.params["mc_amount3"] #{notify.params["mc_amount3"]} == #{payable_subject.subscription_fee.to_s} payable_subject.subscription_fee.to_s
            notify.params["mc_amount1"] #{notify.params["mc_amount1"]} == #{payable_subject.initial_fee.to_s} payable_subject.initial_fee.to_s
          `)
          validation_passed = (notify.params["mc_amount3"] == payable_subject.subscription_fee.to_s) \
            && (notify.params["mc_amount1"] == payable_subject.initial_fee.to_s)
        elsif notify.params["txn_type"] =~ /^subscr_payment$/i
          RAILS_DEFAULT_LOGGER.warn(%Q`
            notify.amount #{notify.amount} == #{payable_subject.initial_fee.to_s} payable_subject.initial_fee.to_s
            notify.complete? #{notify.complete?}
          `)
          validation_passed = (notify.amount.to_s == payable_subject.initial_fee.to_s) && notify.complete?
        end
        RAILS_DEFAULT_LOGGER.debug("^^^notify amount check = #{(notify.amount == payable_subject.initial_fee.to_s).inspect}")
        RAILS_DEFAULT_LOGGER.debug("^^^aloha im in notification validation_passed #{validation_passed.inspect}")
        unless validation_passed
          RAILS_DEFAULT_LOGGER.warn("Failed to verify Paypal's notification for payable #{payable.subject.class.name} #{payable.subject.number}, ID #{payable.subject.id}, please investigate")
          raise SpoofingAttemptError, %Q`PayPal IPN does not match original payable`
        end
      else
        RAILS_DEFAULT_LOGGER.warn(%Q`
          complete? #{notify.complete?}
          payable.id #{payable.id} == notify.invoice #{notify.invoice}
          amount #{payable.amount} == notify.amount #{notify.amount}
          payable.subject.number #{payable.subject.number} == notify.item_id #{notify.item_id}
        `)
        amount_check = false
        notify_item_id_check = false
        notify_complete = notify.complete?
        if notify.params["txn_type"] == "subscr_signup"
          amount_check = payable.amount.to_s == notify.params["mc_amount3"]
          notify_complete = true
          notify_item_id_check = payable.subject.number.to_s == notify.item_id.to_s
        else
          amount_check = payable.amount == notify.amount
          notify_item_id_check = true
        end
        unless notify_complete && payable.id.to_s == notify.invoice.to_s && amount_check && notify_item_id_check
          RAILS_DEFAULT_LOGGER.warn("Failed to verify Paypal's notification for payable #{payable.subject.class.name} #{payable.subject.number}, ID #{payable.subject.id}, please investigate")
          raise SpoofingAttemptError, %Q{PayPal IPN does not match original payable}
        end
      end
      super(payable, who, options.merge(:external_reference_number => notify.transaction_id))
    end

    rescue SpoofingAttemptError
      payable.payment.update_attribute(:ever_failed, true)
      raise
  end
end
