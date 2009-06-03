class FulltextRowUpdate < ActiveRecord::Base
  validates_presence_of :subject_type, :subject_id
  validates_uniqueness_of :subject_id, :scope => :subject_type
  belongs_to :subject, :polymorphic => true
  
  def execute!
    ActiveRecord::Base.transaction do
      if self.deletion?
        FulltextRow.delete_all(:subject_type => self.subject_type, :subject_id => self.subject_id)
      else
        self.subject.send(:update_fulltext_index) if self.subject
      end
      self.destroy
    end
  end
end
