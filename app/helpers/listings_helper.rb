#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ListingsHelper

  def render_listing_thumbnails(listing, domain_home)
    out = []
    pictures = listing.pictures.find(:all, :conditions => 'content_type NOT LIKE "%shockwave-flash%"')
    if !pictures.blank?
      out << %Q!<a id="listing_#{listing.id}_picture" class="main" href="#{domain_home}/#{download_asset_path(:id => pictures.first.id)}" rel="lightbox[#{listing.id}]">!
      out << %Q!<img src="#{domain_home}/#{download_asset_path(:id => pictures.first.id, :size => :small)}" alt="no description" />!
      out << "</a>"
      out << %Q!<ul id="listing_#{listing.id}_thumbnails" class="imagegallery">!
      pictures[1..-1].each do |picture|
        out << render_thumbnail(picture, "mini", listing, domain_home)
      end
      out << "</ul>"
    else
      out << %Q!<div id="listing_#{listing.id}_picture" class="main">!
      out << %Q!<img src="/images/no-image_small.jpg" alt="no description" />!
      out << "</div>"
    end
    out.join("")
  end

  def render_thumbnail(picture, size, listing, domain_home)
    content_tag(:li, %Q[
        <a rel="lightbox[#{listing.id}]" href="#{domain_home}/#{download_asset_path(:id => picture.id)}">
          <img src="#{domain_home}/#{download_asset_path(:id => picture.id, :size => size)}" alt="thumbnail"/>
        </a>]
    )
  end

  def render_add_remove_listings_link(listing, context)
    add_remove_listings(listing, context.current_user, context.current_user?)
  end

  def add_remove_listings(listing, current_user, current_user_exists)
    out = ""
    if current_user_exists
    hide_add = (current_user.listings.map(&:id).include? listing.id) ? true : false
      out = %Q!
        <a id='remove_listing_#{listing.id}_link' onclick="if (confirm('Are you sure?')) { new Ajax.Updater('remove_listing_#{listing.id}_message', '/admin/listings/remove_listings_from_parties', {asynchronous:true, evalScripts:true, parameters:'ids=#{listing.id}&party_ids=#{current_user.id}'}); }; $('add_listing_#{listing.id}_link').toggle(); $('remove_listing_#{listing.id}_link').toggle();return false;" href="#" #{"style='display:none'" if !hide_add}>Remove from My Listings</a>

        <a id='add_listing_#{listing.id}_link' onclick="if (confirm('Are you sure?')) { new Ajax.Updater('add_listing_#{listing.id}_message', '/admin/listings/add_listings_to_parties', {asynchronous:true, evalScripts:true, parameters:'ids=#{listing.id}&party_ids=#{current_user.id}'}); }; $('add_listing_#{listing.id}_link').toggle(); $('remove_listing_#{listing.id}_link').toggle();return false;" href="#" #{"style='display:none'" if hide_add}>Add to My Listings</a>
      !
      out << "<div id=remove_listing_#{listing.id}_message></div>"
      out << "<div id=add_listing_#{listing.id}_message></div>"
    end
    out
  end

  def send_to_contact_link(listing, domain_home, current_page_url, contact_email)
    "/referrals/contact?title=#{u(render_listing_address_area_city_and_zip(listing))}&reference=#{u(listing.dom_id)}&referral_url=#{u(show_listing_url(domain_home, listing))}&return_to=#{u(current_page_url)}&contact=#{u(contact_email)}"
  end

  def send_to_friend_link(listing, domain_home, current_page_url)
    "/referrals/new?title=#{u(render_listing_address_area_city_and_zip(listing))}&reference=#{u(listing.dom_id)}&referral_url=#{u(show_listing_url(domain_home, listing))}&return_to=#{u(current_page_url)}"
  end

  def show_listing_url(domain_home, listing)
    "#{domain_home}/admin/listings/#{listing.id}"
  end

  def render_listing_column(*args)
    all_blank = true
    string = []
    args.each do |arg|
      all_blank = all_blank & arg.blank?
      string << arg.to_s
    end
    return "No info" if all_blank
    string.join("/")
  end

  def render_listing_price(money_object)
    price = money_object.format(:no_cents, :with_currency)
    # price should be in form [currency_sign]XXXXXX[currency_name] at this point
    num = price.slice!(/\d+/)
    return "No info" if num.nil?
    price[0..0] << num.reverse.scan(/\d{1,3}/).join(',').reverse << price[1..-1]
  end

  def render_listing_address_area_city_and_zip(listing)
    listing.quick_description
  end

  def render_listing_size_style_and_price(listing)
    out = []
    out << "#{h(listing.size)} ft<sup>2</sup>" unless listing.size.blank?
    out << listing.style unless listing.style.blank?
    out << "listed at <span class='price'>#{render_listing_price(listing.price)}</span>" unless listing.price.blank?
    return "no info" if out.blank?
    out.join(" ")
  end

  def render_listing_size(listing)
    listing.size.blank? ? "" : "#{h(listing.size)} ft<sup>2</sup>"
  end

  def render_listing_bedrooms_bathrooms(listing)
    out = []
    out << pluralize(listing.bedrooms.to_i, "Bedroom") unless listing.bedrooms.blank?
    out << pluralize(listing.bathrooms.to_i, "Bathroom") unless listing.bathrooms.blank?
    out.join("/")
  end
  
  def render_listing_age_year_built_field_calculator
    %Q`
      var calculateAgeFromYearBuilt = function(yearBuilt){
        var curDate = new Date();
        return (curDate.getFullYear() - parseInt(yearBuilt));
      };
      
      var calculateYearBuiltFromAge = function(age){
        var curDate = new Date();
        return (curDate.getFullYear() - parseInt(age));
      };
    `  
  end

  def render_listing_address_panel(listing)
    %Q`
      #{self.create_countries_and_states_store}

      var addressPanel = new Ext.Panel({
        collapsible: true,
        layout: "form",
        title: "ADDRESS",
        items: [
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Line 1",
            labelSeparator: ":",
            name: "address[line1]",
            value: #{listing.address.line1.to_json}
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Line 2",
            labelSeparator: ":",
            name: "address[line2]",
            value: #{listing.address.line2.to_json}
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Line 3",
            labelSeparator: ":",
            name: "address[line3]",
            value: #{listing.address.line3.to_json}
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "City",
            labelSeparator: ":",
            name: "address[city]",
            value: #{listing.address.city.to_json}
          }),
          new Ext.form.ComboBox({
            fieldLabel: "Prov/State",
            labelSeparator: ":",
            name: "address[state]",
            store: statesStore,
            displayField: 'value',
            valueField: 'id',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            mode: 'local',
            value: #{listing.address.state.to_json}
          }),
          new Ext.form.ComboBox({
            store: countriesStore,
            displayField: 'value',
            valueField: 'id',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            mode: 'local',
            fieldLabel: "Country",
            labelSeparator: ":",
            name: "address[country]",
            value: #{listing.address.country.to_json}
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Postal Code",
            labelSeparator: ":",
            name: "address[zip]",
            value: #{listing.address.zip.to_json}
          })
        ]
      });
    `
  end
  
  def render_listing_detail(listing)
    %Q`
      #{self.render_listing_age_year_built_field_calculator}
    
      var listingYearBuiltField = new Ext.form.TextField({
        fieldLabel: "Year Built",
        labelSeparator: ":",
        name: "listing[year_built]",
        value: #{listing.year_built.to_json}
      });
        
      var listingAgeField = new Ext.form.TextField({
        fieldLabel: "Age",
        labelSeparator: ":",
        name: "listing[age]",
        value: #{listing.age.to_json}
      });
      
      listingAgeField.on("change", function(thisField, newValue, oldValue) {
        listingYearBuiltField.setValue(calculateYearBuiltFromAge(newValue));
      });
      
      listingYearBuiltField.on("change", function(thisField, newValue, oldValue){
        listingAgeField.setValue(calculateAgeFromYearBuilt(newValue));
      });
      
      var listingDetailLeftItems = [
        new Ext.form.TextField({
          fieldLabel: "Listing Owner Email",
          labelSeparator: ":",
          name: "listing[contact_email]",
          value: #{listing.contact_email.to_json}
        }),
        listingYearBuiltField,
        listingAgeField,
        new Ext.form.TextField({
          fieldLabel: "Bedrooms",
          labelSeparator: ":",
          name: "listing[bedrooms]",
          value: #{listing.bedrooms.to_json}
        }),
        new Ext.form.TextField({
          fieldLabel: "Bathrooms",
          labelSeparator: ":",
          name: "listing[bathrooms]",
          value: #{listing.bathrooms.to_json}
        })
      ];
        
      var listingDetailRightItems = [
        new Ext.form.TextField({
          fieldLabel: "MLS #",
          labelSeparator: ":",
          name: "listing[mls_no]",
          value: #{listing.mls_no.to_json}
        }),
        new Ext.form.TextField({
          fieldLabel: "Region",
          labelSeparator: ":",
          name: "listing[region]",
          value: #{listing.region.to_s.to_json}
        }),
        new Ext.form.TextField({
          fieldLabel: "Area",
          labelSeparator: ":",
          name: "listing[area]",
          value: #{listing.area.to_s.to_json}
        }),
        new Ext.form.TextField({
          fieldLabel: "Status",
          labelSeparator: ":",
          name: "listing[status]",
          value: #{listing.status.to_json}
        }),
        new Ext.form.TextField({
          fieldLabel: "Price",
          labelSeparator: ":",
          name: "listing[price]",
          value: #{listing.price.to_s.to_json}
        })
      ];
    
      var listingDetailPanel = new Ext.Panel({
        collapsible: true,
        title: "REAL ESTATE DETAIL",
        layout: "table",
        layoutConfig: { columns: 2 },
        items: [
            {
              layout: "form",
              items: listingDetailLeftItems
            },{ 
              layout: "form",
              items: listingDetailRightItems
            },{
              layout: "form",
              items: [new Ext.form.TextArea({
                fieldLabel: "Description",
                labelSeparator: ":",
                width: 400,
                name: "listing[description]",
                value: #{listing.description.to_json}
              })],
              colspan: 2 
            }
          ]
      });
    `
  end
  
  def render_listing_extras(listing)
    %Q`
      var listingExtrasPanel = new Ext.Panel({
        collapsible: true,
        title: "EXTRA (optional)",
        items: [new Ext.form.TextArea({
          width: 505,
          name: "listing[extras]",
          value: #{listing.extras.to_json}
        })]
      });    
    `
  end
end
