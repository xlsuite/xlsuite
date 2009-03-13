#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AttachmentDrop < Liquid::Drop
  include ActionView::Helpers::NumberHelper
  delegate :size, :filename, :content_type, :to => :attachment
  attr_reader :attachment, :recipient

  def initialize(attachment, recipient)
    @attachment = attachment
    @recipient = recipient
  end

  def human_size
    number_to_human_size(self.size)
  end

  def url
    "http://#{@recipient.domain_name}/admin/a/#{@attachment.uuid}/#{@recipient.uuid}"
  end
end
