class AddDescriptionToCartLinesIfNeeded < ActiveRecord::Migration
  def self.up
    unless CartLine.columns_hash.keys.include?("description")
      add_column :cart_lines, :description, :string
    end
  end

  def self.down
    remove_column :cart_lines, :description
  end
end
