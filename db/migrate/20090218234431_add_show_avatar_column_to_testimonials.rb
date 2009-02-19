class AddShowAvatarColumnToTestimonials < ActiveRecord::Migration
  def self.up
    add_column :testimonials, :show_avatar, :boolean
  end

  def self.down
    remove_column :testimonials, :show_avatar
  end
end
