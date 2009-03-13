#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Interest < ActiveRecord::Base
  acts_as_reportable

  belongs_to :party
  belongs_to :listing

  def short_note
    note ? note[0..100] : ''
  end

  def append_note(text)
    self.note = "" if self.note.blank?
    self.note += "#{text}\n---\n\n" unless text.blank?
  end

  protected

end
