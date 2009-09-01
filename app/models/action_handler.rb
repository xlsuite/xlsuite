class ActionHandler < ActiveRecord::Base
  validates_presence_of :label, :name, :account_id
  validates_uniqueness_of :label, :scope => :account_id
end
