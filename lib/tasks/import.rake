namespace :wpul do
  
  namespace :import do

    require 'csv'
        
    task :destroy => :environment do
      puts "Destroying all records"
      Geoposition.destroy_all
    end
    
    task :us => :environment do
      puts "Importing all US zip code records"
      CSV::Reader.parse(File.open(File.join(RAILS_ROOT, 'data', 'us-zip-codes','5-digit Premium.csv'), 'rb')) do |row|
        unless row[0] == "ZIPCode"
          geoposition = Geoposition.new
          geoposition.zip = row[0]
          geoposition.zip_type = row[1]
          geoposition.city_name = row[2]
          geoposition.city_type = row[3]
          geoposition.state_name = row[4]
          geoposition.state_abbr = row[5]
          geoposition.area_code = row[6]
          geoposition.latitude = row[7]
          geoposition.longitude = row[8]
          geoposition.save
        else
          next
        end
      end
    end

    task :canada => :environment do
      puts "Importing all Canadian postal code records"
      CSV::Reader.parse(File.open(File.join(RAILS_ROOT, 'data', 'canada-postal-codes','6-digit Premium.csv'), 'rb')) do |row|
        unless row[0] == "PostalCode"
          geoposition = Geoposition.new
          geoposition.zip = row[0]
          geoposition.city_name = row[1]
          geoposition.city_type = row[2]
          geoposition.state_name = row[3]
          geoposition.state_abbr = row[4]
          geoposition.latitude = row[5]
          geoposition.longitude = row[6]
          geoposition.save
        else
          next
        end
      end
    end
  end
end

namespace :import do 
  task :invoices => :environment do
    puts "Importing invoices from invoices.txt"
    
    domain_name = "leftcoastlights.com"
    domain = Domain.find_by_name(domain_name)
    unless domain
      puts "Domain #{domain_name} not found"
      return
    end
    
    account = domain.account
    
    f = File.read("invoices.txt")
    data_array = YAML.load(f)
    @imported = 0
    data_array.each do |attrs|
      attrs.symbolize_keys!
      Order.transaction do
        @email = attrs.delete(:customer_email)
        
        @customer = account.parties.find_by_email_address(@email)
        customer_attrs = attrs.delete(:customer_attrs)
        unless @customer
          @customer = account.parties.create!(customer_attrs)
          account.email_contact_routes.create!(:email_address => @email, :routable => @customer) unless @email.blank?
        end

        lines = attrs.delete(:lines)
        
        %w(shipping_fee transport_fee equipment_fee).each do |fee|
          attrs[fee.to_sym] = attrs[fee.to_sym].to_money
        end
        
        ship_to = account.address_contact_routes.build(attrs.delete(:address))
        
        @order = account.orders.build
        @order.attributes = attrs
        @order.invoice_to = @customer
        @order.ship_to = ship_to
        @order.account = account
        @order.save!

        @order.lines.destroy_all
        unless lines.blank?
          lines.each do |line|
            product_name = line.delete(:product_name)
            oline = @order.lines.create!(line)
            unless line[:sku].blank? then
              product = @order.account.products.find_by_sku(line[:sku])
              product = @order.account.products.create!(:sku => line[:sku], :name => line[:description], :retail_price => line[:retail_price], :name => product_name) if product.blank?
              oline.update_attribute(:product_id, product.id)
            end
          end
        end
        
        @imported = @imported+1
      end
    end
    puts "#{@imported} orders successfully imported"
  end
  
  task :estimates => :environment do
    puts "Importing estimates from estimates.txt"
    
    domain_name = "localhost"
    domain = Domain.find_by_name(domain_name)
    unless domain
      puts "Domain #{domain_name} not found"
      return
    end
    
    account = domain.account
    
    f = File.read("estimates.txt")
    data_array = YAML.load(f)
    @imported = 0
    data_array.each do |attrs|
      attrs.symbolize_keys!
      Estimate.transaction do
        @email = attrs.delete(:customer_email)
        
        @customer = account.parties.find_by_email_address(@email)
        customer_attrs = attrs.delete(:customer_attrs)
        unless @customer
          @customer = account.parties.create!(customer_attrs)
          account.email_contact_routes.create!(:email_address => @email, :routable => @customer) unless @email.blank?
        end

        lines = attrs.delete(:lines)
        
        %w(shipping_fee transport_fee equipment_fee).each do |fee|
          attrs[fee.to_sym] = attrs[fee.to_sym].to_money
        end
        
        ship_to = account.address_contact_routes.build(attrs.delete(:address))
        
        @estimate = account.estimates.build
        @estimate.attributes = attrs
        @estimate.invoice_to = @customer
        @estimate.ship_to = ship_to
        @estimate.account = account
        @estimate.save!

        @estimate.lines.destroy_all
        unless lines.blank?
          lines.each do |line|
            product_name = line.delete(:product_name)
            oline = @estimate.lines.create!(line)
            unless line[:sku].blank? then
              product = @estimate.account.products.find_by_sku(line[:sku])
              product = @estimate.account.products.create!(:sku => line[:sku], :name => line[:description], :retail_price => line[:retail_price], :name => product_name) if product.blank?
              oline.update_attribute(:product_id, product.id)
            end
          end
        end
        
        @imported = @imported+1
      end
    end
    puts "#{@imported} estimates successfully imported"
  end
end