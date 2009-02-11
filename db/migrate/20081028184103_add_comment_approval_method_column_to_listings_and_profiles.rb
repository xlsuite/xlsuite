class AddCommentApprovalMethodColumnToListingsAndProfiles < ActiveRecord::Migration
  def self.up
    add_column :listings, :comment_approval_method, :string, :default => "Moderated"
    add_column :profiles, :comment_approval_method, :string, :default => "Moderated"
  end

  def self.down
    remove_column :listings, :comment_approval_method
    remove_column :profiles, :comment_approval_method
  end
end
