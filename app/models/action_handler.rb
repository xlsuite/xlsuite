class ActionHandler < ActiveRecord::Base
  belongs_to :account
  
  validates_presence_of :label, :name, :account_id
  validates_uniqueness_of :label, :scope => :account_id
  
  before_validation :set_label_if_blank
  
  protected
  def set_label_if_blank
    return unless self.label.blank?
    self.set_label
  end

  def set_label
    t_label = self.name.to_s.dup
    t_label.gsub!(/[^(\d\w\s\-_)]/, "")
    t_label.gsub!(/\s+/, " ")
    t_label.downcase!
    t_label.gsub!(/\s/, "-")
    c_label, t_object = nil, nil
    unless t_label.blank?
      count, counter = 0, 0
      c_label = t_label
      loop do
        count = self.class.count(:conditions => {:label => c_label, :account_id => self.account.id})
        counter += 1
        if count > 0
          t_object = self.class.find(:all, :select => "id", :conditions => {:label => c_label, :account_id => self.account.id}).map(&:id)
          if t_object.size > 1
            logger.warn("You should not see this message, found the cause in #{self.class.name}#set_label")
            return
          end
          if t_object.first == self.id
            return
          else
            c_label = t_label + counter.to_s
          end
        else
          break
        end
      end
    else
      c_label = "#{self.class.name.underscore}-#{self.id}" unless self.new_record?
    end
    self.label = c_label
  end  
end
