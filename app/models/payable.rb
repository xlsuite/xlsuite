#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Payable < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation {|p| p.account = p.payment.if_not_nil {|p| p.account} if p.payment}

  belongs_to :payment
  belongs_to :subject, :polymorphic => true
  validates_presence_of :payment_id, :subject_id, :subject_type
  validate_on_create :subject_cant_be_void

  acts_as_money :amount

  belongs_to :voided_by, :class_name => "Party", :foreign_key => "voided_by_id"
  before_save {|r| r.voided_by_name = r.voided_by.if_not_nil {|p| p.name.to_s}}

  def void?
    !!voided_at
  end

  def void!(who, time=Time.now.utc)
    self.voided_at = time
    self.voided_by = who
    self.save!
  end

  %w(start! receive! complete! cancel!).each do |method_name|
    self.class_eval <<-"end_eval"
      def #{method_name}(who, options={})
        self.payment.payment_helper.#{method_name}(self, who, options)
      end
    end_eval
  end

  protected
  def subject_cant_be_void
    return unless self.subject.respond_to?(:void?)
    errors.add(:subject, "can't be void") if self.subject.void?
  end
end
