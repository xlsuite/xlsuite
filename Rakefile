# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/switchtower.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), "config", "boot"))

require "rubygems"

require "rake"
require "rake/testtask"
require "rake/rdoctask"

require "tasks/rails"

namespace :db do
  desc "Dumps the environment's DB to db.sql"
  task :dump => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    db_name = config["database"]
    db_user = config["username"]
    db_pass = config["password"]

    cmd = %W(mysqldump #{db_name.inspect})
    cmd += %W(--user #{db_user.inspect}) unless db_user.blank?
    cmd += %W(--password=#{db_pass.inspect}) unless db_pass.blank?
    cmd << %q(| ruby -n -e "puts $_.sub(/AUTO_INCREMENT=\d+\s/, "")" > db.sql)
    sh cmd.join(" ")
  end

  desc "Loads the environment's DB from db.sql"
  task :load => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    db_name = config["database"]
    db_user = config["username"]
    db_pass = config["password"]

    ActiveRecord::Base.connection.recreate_database(db_name)
    cmd = %W(mysql #{db_name.inspect})
    cmd += %W(--user #{db_user.inspect}) unless db_user.blank?
    cmd += %W(--password=#{db_pass.inspect}) unless db_pass.blank?
    cmd += %W(< db.sql)
    sh cmd.join(" ")

    Rake::Task["db:structure:dump"].invoke
  end

  namespace :structure do
    desc "Dump the database structure to a SQL file -- CUSTOMIZED FOR XLsuite: don't dump MySQL's AUTO_INCREMENT attribute"
    task :dump do
      abcs = ActiveRecord::Base.configurations
      ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
      File.open("db/#{RAILS_ENV}_structure.sql", "w+") do |f|
        f << ActiveRecord::Base.connection.structure_dump.gsub(/AUTO_INCREMENT=\d+\s/, "")
        f << ActiveRecord::Base.connection.dump_schema_information
      end
    end
  end
end
