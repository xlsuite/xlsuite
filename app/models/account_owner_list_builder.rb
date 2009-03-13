#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountOwnerListBuilder < TagListBuilder
  # Unless the sender is authorized to send, return an empty array.
  # This needs to also take into account the E-Mail's creator.
  def to_email_addresses
    sender = self.sender.party
    logger.debug {"==> superuser? #{sender.superuser?}, can?(:send_to_account_owners) #{sender.can?(:send_to_account_owners)}"}
    return [] unless sender.superuser? && sender.can?(:send_to_account_owners)

    if self.tag_names.empty? then
      EmailContactRoute.find_by_sql(<<-EOS
          SELECT cr.* FROM contact_routes cr
            INNER JOIN parties p ON cr.routable_type = 'Party' AND cr.routable_id = p.id
          WHERE cr.type = 'EmailContactRoute'
            AND p.id IN (SELECT party_id FROM accounts)
        EOS
      )
    else
      tags = Tag.find_all_by_name(self.tag_names)
      EmailContactRoute.find_by_sql(<<-EOS
          SELECT cr.* FROM contact_routes cr
            INNER JOIN parties p ON cr.routable_type = 'Party' AND cr.routable_id = p.id
            INNER JOIN taggings tg ON tg.taggable_type = 'Party' AND p.id = tg.taggable_id
          WHERE cr.type = 'EmailContactRoute'
            AND tg.tag_id IN (#{tags.map(&:id).join(', ')})
            AND p.id IN (SELECT party_id FROM accounts)
        EOS
      )
    end
  end

  def sender
    self.email.sender
  end

  def to_s
    "account_owners=#{tag_syntax}"
  end
end
