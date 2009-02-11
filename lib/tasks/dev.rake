namespace :dev do
  desc "Adds domains xlsuite.local, agentxl.local and rickstonehouse.local"
  task :create_local_domains => :environment do
    puts "Before: #{Domain.count} domains"
    xlsuite = Domain.find_by_name("xlsuite.com")
    domain = xlsuite.account.domains.find_or_create_by_name("xlsuite.local")
    domain.activated_at = Time.now.utc
    domain.rebuild_routes!

    weputuplights = Domain.find_by_name("weputuplights.biz")
    domain = weputuplights.account.domains.find_or_create_by_name("weputuplights.local")
    domain.activated_at = Time.now.utc
    domain.rebuild_routes!

    rick = Domain.find_by_name("rickstonehouse.com")
    domain = rick.account.domains.find_or_create_by_name("rickstonehouse.local")
    domain.activated_at = Time.now.utc
    domain.rebuild_routes!

    domain = rick.account.domains.find_or_create_by_name("agentxl.local")
    domain.activated_at = Time.now.utc
    domain.rebuild_routes!

    puts "After: #{Domain.count} domains"
  end

  namespace :db do
    desc "Loads the latest production database in the current environment's"
    task :load => :environment do
      config = ActiveRecord::Base.connection.instance_variable_get("@config")

      begin
        require "cliaws"
      rescue LoadError
        $stderr.puts "This task requires the cliaws RubyGem.  Install using 'gem install cliaws'"
      end

      backups = Cliaws.s3.list("xlsuite_production/db")
      latest_backup = backups.sort.last

      puts "Downloading #{latest_backup}"
      basename = File.basename(latest_backup)
      sh "clis3 get #{latest_backup} tmp/#{basename}"

      puts "Unpacking #{basename}"
      sh "gunzip tmp/#{basename}"

      mysql_command = "mysql"
      mysql_command << " -u#{config[:username]}" unless config[:username].blank?
      mysql_command << " -p#{config[:password]}" unless config[:password].blank?
      mysql_command << " -P#{config[:port]}" unless config[:port].blank?
      mysql_command << " -S#{config[:socket]}" unless config[:socket].blank?

      puts "Dropping existing DB"
      sh mysql_command + %Q( -e "DROP DATABASE #{config[:database]}")

      puts "Creating database"
      sh mysql_command + %Q( -e "CREATE DATABASE #{config[:database]}")

      puts "Loading data into MySQL"
      basename = File.basename(basename, ".gz")
      sh mysql_command + %Q( #{config[:database]} < tmp/#{basename})

      puts "You may want to remove the downloaded backup:"
      puts "  rm tmp/#{basename}"
    end
  end
end
