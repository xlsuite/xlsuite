#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "open-uri"

class RentalsImportFuture < SpiderFuture

  def prepare
    status!(:initializing)
    self.results[:imported_assets_count] = 0
    self.results[:imported_rents_count] = 0
    
    self.account.rents.destroy_all
  end

  def process(uri, page)
    case page.response["content-type"]
    when /xhtml/
      process_html(uri, page)
    when /javascript/
      break
    when /css/
      break
    when /image/
      break
    else
      process_html(uri, page)
    end
  end

  def process_html(uri, page)
    rent = []
    tmp = page.body.gsub(/[\r\n]/,'')
    tmp.scan(/<h2>(.*?)\(map\)<\/h2>.*?Reply to: <a href=\"(.*?)\">(.*?)<\/a><br>.*?Date:(.*?)<br><br><br>(.*?)<table summary(.*?)maps\.google\.com\/\?q=(.*?)\">google map/) do |b,c,d,e,f,g,h|
      title = b
      email = c
      email_show = d
      date = e
      description = f
      address = ""
      map_address = h.to_s;
      map_address = map_address.gsub(/\+/,' ');
      map_address.scan(/loc%3A (.+)/) { |z| address = z } 
      
      begin
        rent = self.account.rents.create!(:description => description.unpack('M*'), :contact_email => email_show)
        
        rent.raw_property_data.merge!("Title" => title, "Link" => uri.to_s, "Date" => date, "Email" => email, "Map address" => map_address, "Address" => address)
        
        title.scan(/\$(\d+)/)
        rent.price = ($1)
        
        title.scan(/(\d)\s*br/)
        rent.bedrooms = ($1)
      
        rent.save!
        
        process_images(uri, rent, page) 
        
        self.results[:imported_rents_count] += 1
      rescue
        log_link_error($!, uri)
      end
    end
    rent
  end
  
  def process_images(uri, rent, page)
    page.search("//img[@src]").each do |img|
      relative_uri = URI.parse(img["src"]) rescue nil
      next if relative_uri.nil?
      image_uri = uri.merge(relative_uri)
      img["src"] = download_asset(image_uri, rent)
    end if page.respond_to?(:search)
  end

  def want_to_spider?(uri)
    uri.to_s.scan(/apa\/index(\d*)\.html/)
    first_x_pages = ($1).nil? ? false : (($1).to_i < 1500)
    ret_val = (root.host == uri.host && !visited_uris.include?(uri) && (uri.to_s =~ /\/apa\/\d+\.html/ || first_x_pages))
    ret_val
  end
  
  def each_link_on(uri, page)
    current_link = nil
    begin
      page.links.each do |link|
        current_link = link
        next if link.href =~ /mailto:/
        yield uri.merge(link.href) if link.href
      end if page.respond_to?(:links)
    rescue
      log_link_error($!, uri, current_link)
    end
  end
  
  def download_asset(asset_uri, rent)
    begin
      asset = rent.assets.create!(:temp_data => open(asset_uri).read,
                                          :filename => File.basename(asset_uri.path),
                                          :owner => self.owner,
                                          :account => self.account)
                                          puts "asset created"
      self.results[:imported_assets_count] += 1 if asset
    rescue
      logger.warn {"==> Could not open #{asset_uri}: #{$!.message}"}
      asset_uri.to_s
    end
  end
  
  def finalize
    status!(:done, 100)
  end
  
  def log_link_error(exception, uri, current_link=nil)
    data = current_link.if_not_nil do |link|
      link.respond_to?(:href) ? [link.text, link.href] : link.inspect
    end

    self.results[:bad_urls] << [uri.to_s, exception.message.to_s[0, 50], data].compact
    self.save!
  end
end
