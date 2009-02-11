require 'lib/attributes.rb'
require 'rubygems'
require 'active_record'
require 'yaml'

options = YAML.load <<-txt
  adapter: postgresql
  database: votelink
  username: www
  host: localhost 
  encoding: UTF8
txt
ActiveRecord::Base.establish_connection options

module MigrationDSL
  attribute :migration

  def migration_class
    model = self
    Class.new(::ActiveRecord::Migration) do
      singleton_class =
        class << self
          self
        end
      singleton_class.module_eval{ attribute :model => model }
      singleton_class.module_eval &model.migration
    end
  end
end

class Table < ActiveRecord::Base
  extend MigrationDSL
end

class Jobs < Table
  migration do
    def up
      create_table model.table_name, :primary_key => model.primary_key do |t|
        t.column 'rockin', :text
      end
    end

    def down
      create_table model.table_name
    end
  end
end
