class DeleteRetsSearchFuturesWithPolygonsButNoPostalCodes < ActiveRecord::Migration
  def self.up
    # Find Rets Search Futures that have a polygon
    rsf=RetsSearchFuture.all.select{|r|r.args[:polygon]}
    # Select those that do not contain postal codes
    deleteFutures =rsf.select{|r| r.args[:lines].map{|l| l[:from] =~ /V\d[A-Z]\s\d[A-Z]\d/}.compact.blank?}

    deleteFutures.map(&:destroy)
  end

  def self.down
  end
end
