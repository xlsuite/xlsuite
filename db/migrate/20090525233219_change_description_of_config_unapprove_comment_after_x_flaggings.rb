class ChangeDescriptionOfConfigUnapproveCommentAfterXFlaggings < ActiveRecord::Migration
  def self.up
    config_description = "Automatically unapprove comments after x number of approved flaggings. Set to 0 to turn this feature off."
    Configuration.update_all("description = '#{config_description}'", "name = 'unapprove_comment_after_x_flaggings'")
  end

  def self.down
  end
end
