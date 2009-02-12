class RemoveCommentApprovalMethodDefaultValue < ActiveRecord::Migration
  def self.up
    change_column :blogs, :comment_approval_method, :string, :default => nil
    change_column :listings, :comment_approval_method, :string, :default => nil
    change_column :products, :comment_approval_method, :string, :default => nil
    change_column :profiles, :comment_approval_method, :string, :default => nil
  end

  def self.down
    change_column :blogs, :comment_approval_method, :string, :default => "Moderated"
    change_column :listings, :comment_approval_method, :string, :default => "Moderated"
    change_column :products, :comment_approval_method, :string, :default => "Moderated"
    change_column :profiles, :comment_approval_method, :string, :default => "Moderated"
  end
end
