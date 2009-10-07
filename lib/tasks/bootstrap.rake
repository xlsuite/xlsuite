require "pp"

def config!(klass, params)
  returning(klass.new) do |config|
    params.each do |k, v|
      config.send("#{k}=", v)
    end
  end.save!
end

namespace :db do
  namespace :structure do
    task :load => :environment do
      config = ActiveRecord::Base.connection.instance_variable_get("@config")
      mysql_command = "mysql"
      mysql_command << " -u#{config[:username]}" unless config[:username].blank?
      mysql_command << " -p#{config[:password]}" unless config[:password].blank?
      mysql_command << " -P#{config[:port]}" unless config[:port].blank?
      mysql_command << " -S#{config[:socket]}" unless config[:socket].blank?
      mysql_command << " #{config[:database]}"
      mysql_command << " < db/development_structure.sql"
      sh mysql_command
    end
  end

  task :bootstrap => :environment do
    Account.transaction do
      puts "Installing initial configuration options, hold on to your chair!"
      config!(FloatConfiguration, :account_id => nil, :float_value => 0, :description => "The default cost of new accounts.  0.00 means to hand out free accounts, at least until they expire.", :domain_patterns => "**", :group_name => "accounts", :account_wide => false, :name => "account_base_cost")
      config!(StringConfiguration, :account_id => nil, :str_value => "/favicon.ico", :group_name => "Display", :description => "Set your favicon url/path here. Please use a 16x16 icon for the best resolution.", :domain_patterns => "**", :account_wide => true, :name => "favicon_url")
      config!(StringConfiguration, :account_id => nil, :str_value => "/images/poweredBy.png", :group_name => "Display", :description => "Main logo. Please use 170x56 picture for the best resolution.", :domain_patterns => "**", :account_wide => true, :name => "logo_url")
      config!(IntegerConfiguration, :account_id => nil, :int_value => 2.hours.to_i, :group_name => "", :description => "The number of seconds with which confirmation tokens are created during signup", :domain_patterns => "**", :account_wide => false, :name => "confirmation_token_duration_in_seconds")
      config!(StringConfiguration, :account_id => nil, :str_value => "/admin", :group_name => "Login", :description => "Main logo. Please use 170x56 picture for the best resolution.", :domain_patterns => "**", :account_wide => true, :name => "login_redirection")
      config!(StringConfiguration, :account_id => nil, :str_value => "put yours here", :group_name => "Google API", :description => "Your google map API key", :domain_patterns => "**", :account_wide => true, :name => "google_maps_api_key")

      puts "Installing initial account, hold on..."
      account = Account.new
      account.expires_at = 10.years.from_now
      account.master     = true
      account.save!

      puts "Creating and activating localhost domain, nearly there..."
      account.domains.create!(:name => "localhost")
      account.domains.first.activate!
      
      puts "Inserting xlsuite.com domain"
      xlsuite_domain = account.domains.create!(:name => "xlsuite.com")
      xlsuite_domain.activate!

      account.layouts.create!(:title => "HTML", :domain_patterns => "**", :body => File.read(File.dirname(__FILE__) + "/layout.html"))
      account.pages.create!(:title => "Home Page", :layout => "HTML", :status => "published", :behavior => "plain_text", :domain_patterns => "**", :fullslug => "/", :body => File.read(File.dirname(__FILE__) + "/home.html"))

      puts "Creating first party (login: 'admin@localhost', password: 'adminadmin'), nearly finished..."
      party = account.parties.create!(:first_name => "", :last_name => "Admin", :password => "adminadmin", :password_confirmation => "adminadmin")
      party.email_addresses.create!(:email_address => "admin@localhost")

      party.append_permissions %w( access_rets admin_forum allow_importing edit_account edit_all_mailings edit_api_keys
          edit_articles edit_attachments edit_blogs edit_candidate edit_catalog edit_categories
          edit_comments edit_configuration edit_contact_request edit_contact_requests edit_contents edit_customer
          edit_destinations edit_domains edit_email_accounts edit_entities edit_estimates edit_feeds
          edit_files edit_groups edit_imports edit_installer edit_layouts edit_link
          edit_listings edit_mappings edit_orders edit_own_account edit_own_attachments edit_own_contacts_only
          edit_own_estimates edit_own_mailings edit_own_quotes edit_own_schedule edit_pages edit_party
          edit_party_security edit_payment edit_profiles edit_profile_requests edit_publishings edit_quote
          edit_redirects edit_roles edit_schedule edit_snippets edit_staff edit_supplier
          edit_team edit_templates edit_testimonials edit_todo edit_workflows
          lush_estimates nameadmin_forum randomize_password send_mail send_to_account_owners
          view_candidate view_catalog view_contact_request view_customer view_entities
          view_estimate view_installer view_invoice view_orders view_own_contacts_only
          view_own_quotes view_own_schedule view_party view_payment view_quote
          view_schedule view_staff view_supplier view_team view_todos)
      party.update_effective_permissions = true
      party.confirm!

      account.update_attribute(:owner, party)

      puts "Done!  Run script/server and Visit http://localhost:3000/"
    end
  end
end
