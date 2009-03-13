#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CommentEstimateLine < EstimateLine
  validates_presence_of :comment

  def comment?; true; end
  
  def main_identifier
    "#{self.estimate.complete_name} : #{self.comment}"
  end
end
