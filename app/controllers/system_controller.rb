#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SystemController < ApplicationController
  skip_before_filter :login_required

  def index
  end
end
