class InitializingPartyPointsFromComments < ActiveRecord::Migration
  def self.up
    created_by = nil
    domain = nil
    points = 0
    Comment.all(:conditions => "approved_at IS NOT NULL AND created_by_id IS NOT NULL").each do |comment|
      created_by = Party.find(comment.created_by_id)
      domain = Domain.find(comment.domain_id)
      points = comment.point_worth
      created_by.add_point_in_domain(points, domain)
      comment.set_point_added(true)
    end
  end

  def self.down
    created_by = nil
    domain = nil
    points = 0
    Comment.all(:conditions => "approved_at IS NOT NULL AND created_by_id IS NOT NULL").each do |comment|
      created_by = Party.find(comment.created_by_id)
      domain = Domain.find(comment.domain_id)
      points = comment.point_worth
      created_by.add_point_in_domain(-points, domain)
      comment.set_point_added(false)
    end
  end
end
