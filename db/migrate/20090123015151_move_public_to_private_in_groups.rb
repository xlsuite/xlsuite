class MovePublicToPrivateInGroups < ActiveRecord::Migration
  def self.up
    Group.update_all("private=1", "public=0")
    Group.update_all("private=0", "public=1")
  end

  def self.down
    Group.update_all("private=1")
  end
end
