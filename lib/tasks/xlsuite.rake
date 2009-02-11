require "benchmark"

namespace :xlsuite do
  desc "Rebuilds the full text indexes"
  task :rebuild_fulltext_indexes => :environment do
    puts "Searching for models to rebuild..."
    fulltext_models = Dir[File.join(RAILS_ROOT, "app", "models", "*.rb")].select do |file|
      File.read(file) =~ /acts_as_fulltext/
    end

    puts "#{fulltext_models.size} fulltext models"
    ActiveRecord::Base.transaction do
      FulltextRow.delete_all
      fulltext_models.sort.map {|file| File.basename(file, ".rb").classify.constantize}.each do |klass|
        print "Rebuilding #{klass.name} index...\t"
        $stdout.flush
        time = Benchmark.measure do
          klass.rebuild_index
        end
        printf "%6.2fs\n", time.real
        $stdout.flush
      end
    end

    puts "Optimizing fulltext_rows table"
    ActiveRecord::Base.connection.execute "OPTIMIZE TABLE fulltext_rows"
  end

  desc "Copies the current xltester database to the development environment"
  task :copy_xltester => :environment do
    sh "ssh xltester@teksol.info 'cd xltester.com && rake db:dump RAILS_ENV=production && rm db.sql.bz2 && nice bzip2 db.sql'"
    sh "scp xltester@teksol.info:xltester.com/db.sql.bz2 db.sql.bz2"
    rm "db.sql"
    sh "bunzip2 db.sql.bz2"
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:load"].invoke
    Rake::Task["db:migrate"].invoke
  end

  desc "Copies layouts, pages and snippets from one account to another one.  Expects FROM_ACCOUNT and TO_ACCOUNT, which may be an account ID or domain name."
  task :copy_cms => :environment do
    from_account = if ENV["FROM_ACCOUNT"].to_i.zero? then
                     domain = Domain.find_by_name(ENV["FROM_ACCOUNT"])
                     raise "Unknown FROM_ACCOUNT: #{ENV["FROM_ACCOUNT"].inspect}" unless domain
                     domain.account
                   else
                     Account.find(ENV["FROM_ACCOUNT"])
                   end
    to_account = if ENV["TO_ACCOUNT"].to_i.zero? then
                   domain = Domain.find_by_name(ENV["TO_ACCOUNT"])
                   raise "Unknown TO_ACCOUNT: #{ENV["TO_ACCOUNT"].inspect}" unless domain
                   domain.account
                 else
                   Account.find(ENV["TO_ACCOUNT"])
                 end

    raise ArgumentError, "Expected FROM_ACCOUNT and TO_ACCOUNT environment variables to be something meaningful, they were\n  FROM_ACCOUNT:  #{ENV["FROM_ACCOUNT"].inspect}\n  TO_ACCOUNT: #{ENV["TO_ACCOUNT"].inspect}" unless [from_account, to_account].all? {|a| a.kind_of?(Account)}
    puts "Adding pages in #{from_account.domain_name} to #{to_account.domain_name}"
    ActiveRecord::Base.transaction do
      %w(layouts pages snippets).each do |klass|
        from_account.send(klass).each do |obj|
          begin
            attrs = obj.attributes
            attrs.delete(:account)
            attrs.delete(:account_id)
            to_account.logger.debug {"==> Adding to account #{to_account.id}, #{obj.class.name}, #{attrs.inspect}"}
            klass.singularize.classify.constantize.create!(attrs.merge(:account => to_account))
          rescue ActiveRecord::RecordInvalid
            puts obj.to_yaml
            raise
          end
        end
      end
    end
  end
end
