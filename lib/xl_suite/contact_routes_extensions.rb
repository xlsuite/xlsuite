#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module ContactRoutesExtensions
    def offices
      find(:all, :conditions => ["name LIKE ?", "%office%"])
    end

    def faxes
      find(:all, :conditions => ["name LIKE ?", "%fax%"])
    end

    def cells
      find(:all, :conditions => ["name LIKE ?", "%cell%"])
    end

    def mobiles
      find(:all, :conditions => ["name LIKE ?", "%mobile%"])
    end

    def homes
      find(:all, :conditions => ["name LIKE ?", "%home%"])
    end

    def mains
      find(:all, :conditions => ["name LIKE ?", "main%"])
    end

    def blogs
      find(:all, :conditions => ["name LIKE ?", "blog%"])
    end
  end
end
