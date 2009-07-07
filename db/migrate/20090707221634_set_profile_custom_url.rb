class SetProfileCustomUrl < ActiveRecord::Migration
  def self.up
    Profile.all.each do |profile|
      profile.send(:set_custom_url_if_blank)
    end
  end

  def self.down
  end
end
