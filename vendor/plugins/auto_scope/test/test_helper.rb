require "fileutils"
require "test/unit"
require "active_support"
require "active_record"
require File.dirname(__FILE__) + "/../init.rb"

class Contact < ActiveRecord::Base
  has_many :testimonials
end

class Testimonial < ActiveRecord::Base
  belongs_to :contact
  auto_scope \
      :unapproved => {
          :find => {:conditions => "approved_at IS NULL"},
          :create => {:approved_at => nil}},
      :approved => {
          :find => {:conditions => ["approved_at < ?", proc {Time.now}]},
          :create => {:approved_at => proc {Time.now}}}
end

FileUtils.rm_rf("db")
FileUtils.mkdir("db")
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "db/auto_scope_test.db")
#ActiveRecord::Base.logger = Logger.new($stderr)

class CreateContact < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.column :name, :string
    end
  end
end
CreateContact.up

class CreateTestimonial < ActiveRecord::Migration
  def self.up
    create_table :testimonials do |t|
      t.column :contact_id, :integer
      t.column :name, :string
      t.column :approved_at, :datetime
    end
  end
end
CreateTestimonial.up
