#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RetsListingUpdator < RetsSearchFuture
  def run_rets_with_grouping(rets)
    begin
      Listing.all(:select => "account_id, rets_resource, rets_class", :group => "account_id, rets_resource, rets_class").each do |group|
        conds = ["external_id IS NOT NULL AND rets_resource = ? AND rets_class = ? AND status = ?", group.rets_resource, group.rets_class, "active"]
        group_account = Account.find_by_id(group.account_id)
        next unless group_account
        mls_nos = group_account.listings.find(:all, :select => "DISTINCT mls_no", :conditions => conds, :order => "updated_at", :limit => 1000).map(&:mls_no)
        next if mls_nos.empty?

        earliest_listing = group_account.listings.find_by_mls_no(mls_nos.first)
        mls_field = RetsMetadata.find_all_fields(group.rets_resource, group.rets_class).detect {|f| f.description =~ /MLS Number/i}
        date_field = RetsMetadata.find_all_fields(group.rets_resource, group.rets_class).detect {|f| f.description =~ /Last Trans Date/i}
        self.args[:limit] = mls_nos.size
        self.args[:search] = {:resource => group.rets_resource, :class => group.rets_class, :limit => mls_nos.size}
        self.args[:lines] = [ {:operator => "eq", :field => mls_field.value, :from => mls_nos.join(","), :to => ""},
          {:operator => "greater", :field => date_field.value, :from => earliest_listing.updated_at.to_date.to_s(:iso), :to => ""}]
        self.account = group_account # We must be part of an account to be correctly searched upon
        self.save(false) # If we crash, we'll at least have a record of what we did prior to the crash

        begin
          ActiveRecord::Base.transaction do
            rets_search_result = self.run_rets_without_grouping(rets, self.priority)
            inactive_mls_nos = mls_nos - rets_search_result.map{|e| e[:mls_no]}.uniq
            
            inactive_mls_nos.each do |mls_no|
              group_account.listings.find_all_by_mls_no(mls_no).each do |listing|
                if listing.tag_list =~ /sold/i
                  listing.tag_list += " removed"
                else
                  listing.tag_list = "removed"
                  listing.status = "[XL]Inactive"
                  listing.change_to_private
                end
                listing.save!
              end
            end
          end
        rescue
          logger.warn("FAIL ON UPDATING LISTINGS AUTOMATICALLY")
          logger.warn($!.inspect)
        end
      end
    ensure
      self.account = nil
      self.save(false)
    end
  end
  alias_method_chain :run_rets, :grouping

  protected
  def query_is_valid
    # NOP
  end

  def query_must_have_at_least_one_line
    # NOP
  end
end
