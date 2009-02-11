class ChangeS3AccessFlagOnAmazon < ActiveRecord::Migration
  def self.up
    Asset.find(:all, :select => "assets.id").each_slice(200) do |assets|
      MethodCallbackFuture.create!(:system => true, :models => assets, :method => "set_storage_access")
    end
  end

  def self.down
  end
end
