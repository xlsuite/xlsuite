class InitializeYearMonthDayInAffiliateAccountTrackings < ActiveRecord::Migration
  def self.up
    created_at = nil
    AffiliateAccountTracking.all.each do |at|
      next unless at.month.blank?
      created_at = at.created_at
      at.year = created_at.year
      at.month = created_at.month
      at.day = created_at.day
      at.save
    end
  end

  def self.down
  end
end
