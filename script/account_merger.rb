require "main"

def logger
  RAILS_DEFAULT_LOGGER
end

def merge(from_account, to_account)
  puts "Merging account #{from_account.domain_name.inspect} into #{to_account.domain_name.inspect}"
  puts "Press <Enter> to proceed"
  gets
  puts "Starting merging process..."

  exclusions = [AccountAuthorization, Configuration, RetsMetadata]
  klasses = []
  klasses_with_account = []
  klasses_with_user = []
  klasses_with_party = []

  Dir["app/models/*.rb"].each do |filename|
    next if filename =~ /metadata/
    singular_model_name = File.basename(filename, ".rb")

    klass = singular_model_name.classify.constantize

    next unless klass.superclass == ActiveRecord::Base
    klasses << klass
    klasses_with_account << klass if klass.column_names.include?("account_id") && !exclusions.include?(klass)
    klasses_with_user << klass if klass.column_names.include?("user_id")
    klasses_with_party << klass if klass.column_names.include?("party_id")
  end

  ActiveRecord::Base.transaction do
    from_account.assets.find(:all).each do |source_asset|
      target_asset = to_account.assets.find_by_filename(source_asset.filename)
      next unless target_asset
      puts source_asset.filename
      puts "Asset with filename #{source_asset.filename} found in the target account"
      source_asset.destroy
      View.update_all(["asset_id = ?", target_asset.id], ["asset_id = ?", source_asset.id])
    end
    Asset.update_all(["account_id = ?", to_account.id], ["account_id = ?", from_account.id])

    # Email#message_id
    puts
    from_account.emails.find(:all).each do |source_email|
      target_email = to_account.emails.find_by_message_id(source_email.message_id)
      next unless target_email
      source_email.destroy
    end
    Email.update_all(["account_id = ?", to_account.id], ["account_id = ?", from_account.id])
    Recipient.update_all(["account_id = ?", to_account.id], ["account_id = ?", from_account.id])

    # Party update based on email contact routes
    puts
    from_account.email_contact_routes.find(:all).each do |source_email_route|
      next unless source_email_route.routable && source_email_route.routable.kind_of?(Party)
      target_party = Party.find_by_account_and_email_address(to_account, source_email_route.email_address)
      if target_party then
        puts "#{source_email_route.email_address.inspect} found in the target account"
        # combine information of source party to the target party including their routes
        source_party = source_email_route.routable
        %w(addresses phones links).each do |routes|
          source_party.send(routes).each do |route|
            route.account = to_account
            route.routable = target_party
            route.save!
          end
        end

        klasses_with_user.each do |klass|
          klass.update_all(["user_id = ?", target_party.id], ["user_id = ?", source_party.id])
        end

        klasses_with_party.each do |klass|
          klass.update_all(["party_id = ?", target_party.id], ["party_id = ?", source_party.id])
        end

        # delete the party, will also delete other related items including the routes
        source_party.destroy
      else
        source_party = source_email_route.routable
        source_party.update_attribute(:account_id, to_account.id)
        source_email_route.update_attribute(:account_id, to_account.id)
        ContactRoute.update_all(["account_id = ?", to_account.id],
                                ["account_id = ? AND routable_type = ? AND routable_id = ?", from_account.id, "Party", source_party.id])
      end
    end

    puts "Moving listings..."
    to_mls_nos = ActiveRecord::Base.connection.select_values("SELECT mls_no FROM listings WHERE account_id = #{to_account.id}")
    Listing.delete_all(["account_id = ? AND mls_no IN (?)", from_account.id, to_mls_nos.reject(&:blank?)])
    Listing.update_all(["account_id = ?", to_account.id], ["account_id = ?", from_account.id])

    # CMS and domains
    from_account_domain_names = from_account.domains.map(&:name).join(", ")

    puts "Moving domains"
    Domain.update_all(["account_id = ?", to_account.id], ["account_id = ?", from_account.id])
    puts "Moving layouts..."
    Layout.update_all(["account_id = ?, domain_patterns = ?", to_account.id, from_account_domain_names], ["account_id = ?", from_account.id])
    puts "Moving items (pages and snippets)..."
    Item.update_all(["account_id = ?, domain_patterns = ?", to_account.id, from_account_domain_names], ["account_id = ?", from_account.id])

    puts "Moving tags..."
    from_tags = ActiveRecord::Base.connection.select_values("SELECT LOWER(name) FROM tags WHERE account_id = #{from_account.id}")
    to_tags = ActiveRecord::Base.connection.select_values("SELECT LOWER(name) FROM tags WHERE account_id = #{to_account.id}")
    missing_tags = from_tags - to_tags
    unless missing_tags.empty?
      sql = []
      missing_tags.each do |name|
        sql << "(#{ActiveRecord::Base.connection.quote(name)}, #{to_account.id})"
      end

      ActiveRecord::Base.connection.execute("INSERT INTO tags(name, account_id) VALUES #{sql.join(",")}")
    end

    # Update tagging relations
    from_tags.each do |name|
      Tagging.update_all(["tag_id = (SELECT id FROM tags WHERE account_id = ? AND name = ?)", to_account.id, name], ["tag_id = (SELECT id FROM tags WHERE account_id = ? AND name = ?)", from_account.id, name])
    end
    Tag.delete_all(["account_id = ?", from_account.id])

    # update all account_id column of active record classes
    puts
    klasses_with_account.each do |klass|
      puts klass
      klass.update_all(["account_id = ?", to_account.id], ["account_id = ?", from_account.id])
    end

    # delete all excluded classes from the source account
    puts
    exclusions.each do |klass|
      next unless klass.column_names.index("account_id")
      count = klass.delete_all(["account_id = ?", from_account.id]) 
      puts "Destroyed #{count} #{klass.name.pluralize}"
    end

    puts
    puts "Destroying account with ID: #{from_account.id}"
    from_account.destroy

    puts "Your last chance to abort:  press CTRL+C to cancel everything, <Enter> to proceed."
    gets
  end
end

Main {
  argument("from_domain") { required }
  argument("to_domain") { required }

  def run
    from_domain_name = params["from_domain"].value
    from_domain = Domain.find_by_name(from_domain_name)
    raise "Couldn't not find domain named #{from_domain_name.inspect}" if from_domain.blank?

    to_domain_name = params["to_domain"].value
    to_domain = Domain.find_by_name(to_domain_name)
    raise "Couldn't not find domain named #{to_domain_name.inspect}" if to_domain.blank?

    raise "Can't merge inside the same account" if from_domain.account == to_domain.account
    merge(from_domain.account, to_domain.account)
  end
}
