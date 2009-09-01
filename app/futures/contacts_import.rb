#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ContactsImport < Future
  def run
    Import.find(:all, :conditions => "state = 'Scheduled'",
              :order => "created_at", :limit => 10).each do |import|
      begin
        if import.scrape && (import.csv == nil)
          import.scrape!
        end
        import.go!
      rescue ImportAbortedByErrors
      	# Don't try to import again
      	import.update_attribute("state", "Failed")
      rescue InvalidScrapeUrl
        import.update_attribute("state", "Invalid URL")
      rescue ScrapeAbortedByErrors
        import.update_attribute("state", "Scrape Failed")
      end
    end

    self.complete!
  end
end
