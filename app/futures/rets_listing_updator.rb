#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RetsListingUpdator < RetsSearchFuture
  def run
    unless self.system?
      raise MissingAccountAuthorization.new("rets_import") unless self.account.options.rets_import?
    end

    puts("^^^RetsListingUpdator#run")
    status!(:logging_in, 10)
    status!(:querying, 20)
    run_rets(self.client)

    self.complete!
  end
  
  def run_rets_with_grouping(tclient)
    begin
      Listing.all(:select => "account_id, rets_resource, rets_class", :group => "account_id, rets_resource, rets_class").each do |group|
        next if group.rets_resource.blank? || group.rets_class.blank?
        conds = ["external_id IS NOT NULL AND rets_resource = ? AND rets_class = ? AND status = ?", group.rets_resource, group.rets_class, "active"]
        group_account = Account.find_by_id(group.account_id)
        next unless group_account
        mls_nos_all = group_account.listings.find(:all, :select => "DISTINCT mls_no", :conditions => conds, :order => "updated_at").map(&:mls_no)
        mls_nos_all = mls_nos_all.reject(&:blank?)
        next if mls_nos_all.empty?
        mls_field = RetsMetadata.find_all_fields(group.rets_resource, group.rets_class).detect {|f| f.description =~ /MLS Number/i}
        
        redo_times = 0
        mls_nos_all.each_slice(100) do |mls_nos|
          self.args[:limit] = mls_nos.size
          self.args[:search] = {:resource => group.rets_resource, :class => group.rets_class, :limit => mls_nos.size}
          self.args[:lines] = [ {:operator => "eq", :field => mls_field.value, :from => mls_nos.join(","), :to => ""} ]
          self.account = group_account # We must be part of an account to be correctly searched upon
          self.save(false) # If we crash, we'll at least have a record of what we did prior to the crash

          begin
            tclient.transaction do |rets|
              ActiveRecord::Base.transaction do
                puts("^^^Trying to connect to RETS to update listing with MLS nos: #{mls_nos.inspect}")
                rets_search_result = self.run_rets_without_grouping(rets, self.priority, false)
                inactive_mls_nos = mls_nos - rets_search_result.map{|e| e[:mls_no]}.uniq
                puts("^^^Returned MLS nos: #{rets_search_result.map{|e| e[:mls_no]}.uniq.inspect}")
                puts("^^^So inactive MLS nos: #{inactive_mls_nos.inspect}")
                inactive_mls_nos.each do |mls_no|
                  group_account.listings.find_all_by_mls_no(mls_no).each do |listing|
                    if listing.tag_list =~ /sold/i
                      listing.tag_list += " removed"
                    else
                      listing.tag_list += " removed"
                      listing.status = "[XL]Inactive"
                      listing.change_to_private
                    end
                    listing.save!
                  end
                end
              end
            end
          rescue XlSuite::Rets::RetsClient::LookupFailure => e
            error_message = e.message
            puts("^^^EXCEPTION ON RETS AUTO IMPORT #{error_message}")
            if error_message.match(/User\sAgent\snot\sregistered\sor\sdenied/i)
              sleep(5)
              redo_times += 1
              puts("^^^REDOING FOR THE #{redo_times} TIME")
              redo
            else
              raise e
            end
          rescue RETS4R::Client::LoginError => e
            puts("^^^RETS4R Client LoginError #{e.message}")
            sleep(5)
            redo_times += 1
            puts("^^^REDOING FOR THE #{redo_times} TIME")
            redo
          end  
          sleep(5)
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
