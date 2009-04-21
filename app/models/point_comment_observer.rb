#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PointCommentObserver < ActiveRecord::Observer
  observe :comment

  def before_save(comment)
    return if comment.new_record?
    comment.instance_variable_set(:@_old_record, comment.class.find(comment.id))
  end

  def after_save(comment)
    old_record = comment.instance_variable_get(:@_old_record)
    new_creator = comment.created_by
    old_creator = nil
    old_creator = old_record.created_by if old_record
    return unless new_creator
    # If old record doesn't exist
    #   Add points to comment creator
    # If old record exists AND comment changes from unapproved to approved
    #   Add points to comment creator
    # If old record exists AND comment status changes from approved to unapproved
    #   Remove points from comment creator
        
    if old_record.blank? # The else block will get executed only if the comment was a new record
      comment.add_points!
    else 
      if !old_record.approved? && comment.approved? 
        # Add points when the comment changes from unapproved to approved
        comment.add_points!
      elsif old_record.approved? && !comment.approved? 
        # Remove points when the comment changes from approved to unapproved
        old_record.remove_points!
      end
    end
  end
end
