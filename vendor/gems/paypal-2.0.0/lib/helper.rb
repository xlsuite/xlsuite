module Paypal 
  # This is a collection of helpers which aid in the creation of paypal buttons 
  # 
  # Example:
  #
  #    <%= form_tag Paypal::Notification.ipn_url %>
  #    
  #      <%= paypal_setup "Item 500", Money.us_dollar(50000), "bob@bigbusiness.com" %>  
  #      Please press here to pay $500US using paypal. <%= submit_tag %>
  #    
  #    <% end_form_tag %> 
  #
  # For this to work you have to include these methods as helpers in your rails application.
  # One way is to add "include Paypal::Helpers" in your application_helper.rb
  # See Paypal::Notification for information on how to catch payment events. 
  module Helpers
    
    # Convenience helper. Can replace <%= form_tag Paypal::Notification.ipn_url %>
    # takes optional url parameter, default is Paypal::Notification.ipn_url
    def paypal_form_tag(url = Paypal::Notification.ipn_url, options = {})
      form_tag(url, options)
    end

    # This helper creates the hidden form data which is needed for a paypal purchase. 
    # 
    # * <tt>item_number</tt> -- The first parameter is the item number. This is for your personal organization and can 
    #   be arbitrary. Paypal will sent the item number back with the IPN so its a great place to 
    #   store a user ID or a order ID or something like  this. 
    #
    # * <tt>amount</tt> -- should be a parameter of type Money ( see http://leetsoft.com/api/money ) but can also 
    #   be a string of type "50.00" for 50$. If you use the string syntax make sure you set the current 
    #   currency as part of the options hash. The default is USD
    #
    # * <tt>business</tt> -- This is your paypal account name ( a email ). This needs to be a valid paypal business account.
    #
    # The last parameter is a options hash. You can set or override any Paypal-recognized parameter, including:
    #
    # * <tt>:cmd</tt> -- default is '_xclick'.
    # * <tt>:quantity</tt> -- default is '1'.
    # * <tt>:no_note</tt> -- default is '1'.
    # * <tt>:item_name</tt> -- default is 'Store purchase'. This is the name of the purchase which will be displayed
    #   on the paypal page. 
    # * <tt>:no_shipping</tt> -- default is '1'. By default we tell paypal that no shipping is required. Usually
    #   the shipping address should be collected in our application, not by paypal. 
    # * <tt>:currency</tt> -- default is 'USD'. If you provide a Money object, that will automatically override
    #   the value.
    # * <tt>:charset</tt> -- default is 'utf-8'.
    # * <tt>:notify_url</tt> -- If provided paypal will send its IPN notification once a 
    #   purchase is made, canceled or any other status changes occur.
    # * <tt>:return</tt> -- If provided paypal will redirect a user back to this url after a 
    #   successful purchase. Useful for a kind of thankyou page. 
    # * <tt>:cancel_return</tt> -- If provided paypal will redirect a user back to this url when
    #   the user cancels the purchase.
    # * <tt>:tax</tt> -- the tax for the store purchase. Same format as the amount parameter but optional
    # * <tt>:invoice</tt> -- Unique invoice number. User will never see this. optional
    # * <tt>:custom</tt> -- Custom field. User will never see this. optional
    #
    # Generating encrypted form data
    #
    # The helper also supports the generation of encrypted button data. Please see the README for more information
    # on the setup and prerequisite steps for using encrypted forms.
    #
    # The following options must all be provided (as strings) to encrypt the data:
    #
    # * <tt>:business_key</tt> -- The private key you have generated
    # * <tt>:business_cert</tt> -- The public certificate you have also uploaded to Paypal
    # * <tt>:business_certid</tt> -- The certificate ID that Paypal has assigned to your certificate.
    # 
    # Examples:
    #   
    #   <%= paypal_setup @order.id, Money.us_dollar(50000), "bob@bigbusiness.com" %>  
    #   <%= paypal_setup @order.id, '50.00', "bob@bigbusiness.com", :currency => 'USD' %>  
    #   <%= paypal_setup @order.id, '50.00', "bob@bigbusiness.com", :currency => 'USD', :notify_url => url_for(:only_path => false, :action => 'paypal_ipn') %>  
    #   <%= paypal_setup @order.id, Money.ca_dollar(50000), "bob@bigbusiness.com", :item_name => 'Snowdevil shop purchase', :return_url => paypal_return_url, :cancel_url => paypal_cancel_url, :notify_url => paypal_ipn_url  %>  
    #   <%= paypal_setup @order.id, Money.ca_dollar(50000), "bob@bigbusiness.com", :item_name => 'Snowdevil shop purchase', :return_url => paypal_return_url, :cancel_url => paypal_cancel_url, :business_key => @business_key, :business_cert => @business_cert, :business_certid => @business_certid  %>  
    # 
    def paypal_setup(item_number, amount, business, options = {})
      
      misses = (options.keys - valid_setup_options)
      raise ArgumentError, "Unknown option #{misses.inspect}" if not misses.empty?

      params = {
        :cmd => "_ext-enter",
        :redirect_cmd => "_xclick",
        :quantity => 1,
        :business => business,
        :item_number => item_number,
        :item_name => 'Store purchase',
        :no_shipping => '1',
        :no_note => '1',
        :charset => 'utf-8'
      }.merge(options)
            
      params[:currency_code] = amount.currency if amount.respond_to?(:currency)
      params[:currency_code] = params.delete(:currency) if params[:currency]
      params[:currency_code] ||= 'USD'

      # We accept both strings and money objects as amount    
      amount = amount.cents.to_f / 100.0 if amount.respond_to?(:cents)
      params[:amount] = sprintf("%.2f", amount)
      
      # same for tax
      tax = params[:tax]
      if tax
        tax = tax.cents.to_f / 100.0 if tax.respond_to?(:cents)
        params[:tax] = sprintf("%.2f", tax)
      end

      # look for encryption parameters, save them outsite the parameter hash.
      business_key = params.delete(:business_key)
      business_cert = params.delete(:business_cert)
      business_certid = params.delete(:business_certid)

      # Build the form 
      returning button = [] do
        # Only attempt an encrypted form if we have all the required fields.
        if business_key and business_cert and business_certid
          require 'openssl'

          # Convert the key and certificates into OpenSSL-friendly objects.
          paypal_cert = OpenSSL::X509::Certificate.new(Paypal::Notification.paypal_cert)
          business_key = OpenSSL::PKey::RSA.new(business_key)
          business_cert = OpenSSL::X509::Certificate.new(business_cert)
          # Put the certificate ID back into the parameter hash the way Paypal wants it.
          params[:cert_id] = business_certid

          # Prepare a string of data for encryption
          data = ""
          params.each_pair {|k,v| data << "#{k}=#{v}\n"}

          # Sign the data with our key/certificate pair
          signed = OpenSSL::PKCS7::sign(business_cert, business_key, data, [], OpenSSL::PKCS7::BINARY)
          # Encrypt the signed data with Paypal's public certificate.
          encrypted = OpenSSL::PKCS7::encrypt([paypal_cert], signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"), OpenSSL::PKCS7::BINARY)

          # The command for encrypted forms is always '_s-xclick'; the real command is in the encrypted data.
          button << tag(:input, :type => 'hidden', :name => 'cmd', :value => "_s-xclick")
          button << tag(:input, :type => 'hidden', :name => 'encrypted', :value => encrypted)
        else
          # Just emit all the parameters that we have as hidden fields.
          # Note that the sorting isn't really needed, but it makes testing a lot easier for now.
          params.each do |key, value|
            button << tag(:input, :type => 'hidden', :name => key, :value => value)
          end
        end
      end.join("\n")
    end
    
    
    # Pass an address to paypal so that all singup forms can be prefilled
    #
    # * <tt>email</tt> --	Customer's email address
    # * <tt>first_name</tt> --	Customer's first name. Must be alpha-numeric, with a 32 character limit
    # * <tt>last_name</tt> --	Customer's last name. Must be alpha-numeric, with a 64 character limit
    # * <tt>address1</tt> --	First line of customer's address. Must be alpha-numeric, with a 100 character limit
    # * <tt>address2</tt> --	Second line of customer's address. Must be alpha-numeric, with a 100 character limit
    # * <tt>city</tt> --	City of customer's address. Must be alpha-numeric, with a 100 character limit
    # * <tt>state</tt> --	State of customer's address. Must be official 2 letter abbreviation
    # * <tt>zip</tt> --	Zip code of customer's address
    # * <tt>night_phone_a</tt> --	Area code of customer's night telephone number
    # * <tt>night_phone_b</tt> --	First three digits of customer's night telephone number
    # * <tt>day_phone_a</tt> --	Area code of customer's daytime telephone number
    # * <tt>day_phone_b</tt> --	First three digits of customer's daytime telephon
    def paypal_address(options = {})
      options.collect do |key, value|
        tag(:input, :type => 'hidden', :name => key, :value => value)
      end.join("\n")
    end
    
    private
    
    # See https://www.paypal.com/IntegrationCenter/ic_std-variable-reference.html for details on the following options.
    def valid_setup_options
      [
      # Generic Options
      :cmd,
      # IPN Support
      :notify_url,
      # Item Information
      :item_name,
      :quantity,
      :undefined_quantity,
      :on0,
      :os0,
      :on1,
      :os1,
      # Display Information
      :add,
      :cancel_return,
      :cbt,
      :cn,
      :cpp_header_image,
      :cpp_headerback_color,
      :cpp_headerborder_color,
      :cpp_payflow_color,
      :cs,
      :display,
      :image_url,
      :no_note,
      :no_shipping,
      :page_style,
      :return,
      :rm,
      # Transaction Information
      :address_override,
      :currency,
      :currency_code,
      :custom,
      :handling,
      :invoice,
      :redirect_cmd,
      :shipping,
      :tax,
      :tax_cart,
      # Shopping Cart Options
      :amount,
      :business,
      :handling_cart,
      :paymentaction,
      :rupload,
      :charset,
      :upload,
      # Prepopulating PayPal FORMs or Address Overriding
      :address1,
      :address2,
      :city,
      :country,
      :email,
      :first_name,
      :last_name,
      :lc,
      :night_phone_a,
      :night_phone_b,
      :night_phone_c,
      :state,
      :zip,
      # Prepopulating Business Account Sign-up
      :business_address1,
      :business_address2,
      :business_city,
      :business_state,
      :business_country,
      :business_cs_email,
      :business_cs_phone_a,
      :business_cs_phone_b,
      :business_cs_phone_c,
      :business_url,
      :business_night_phone_a,
      :business_night_phone_b,
      :business_night_phone_c,
      # End of list from https://www.paypal.com/IntegrationCenter/ic_std-variable-reference.html
      # The following items are known to exist but are not yet on the above page.
      :business_zip,
      :day_phone_a,
      :day_phone_b,
      :day_phone_c,
      # Subscription Options
      :a1, # Trial Amount 1
      :p1, # Trial Period 1
      :t1, # Trial Period 1 Units (D=days, W=weeks, M=months, Y=years)
      :a2, # Trial Amount 2
      :p2, # Trial Period 2
      :t2, # Trial Period 2 Units
      :a3, # Regular Subscription Amount
      :p3, # Regular Subscription Period
      :t3, # Regular Subscription Period Units
      :src, # Recurring Payments? (1=yes, default=0)
      :sra, # Reattempt Transaction on Failure? (1=yes, default=0)
      :srt, # Recurring Times (number of renewals before auto-cancel, default=forever)
      :usr_manage, # Username and Password Generator? (1=yes, default=0)
      :modify, # Modification Behaviour (0=new subs only, 1=new or modify, 2=modify existing only, default=0)
      # Encryption Options - used internally only.
      :business_key, # Your private key
      :business_cert, # Your public certificate
      :business_certid # Your public certificate ID (from Paypal)
      ]
    end
    
  end
end
