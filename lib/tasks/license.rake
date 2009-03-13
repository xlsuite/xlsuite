namespace :license do
  task :apply do
    require 'mmcopyrights'
    %w(app lib).each do |dir|
      MM::Copyrights.process(dir, "rb", "#-", "XLsuite, an integrated CMS, CRM and ERP for medium businesses\nCopyright 2005-#{Date.today.year} iXLd Media Inc.  See LICENSE for details.")
    end
  end

  task :clean do
    FileList["{app,lib}/**/*.rb"].each do |file|
      File.open(file + ".new", "w") do |modified|
        File.open(file, "r") do |original|
          original.each do |line|
            modified.puts line unless line =~ /^#\s/ .. line =~ /^#\s+END OF TERMS AND CONDITIONS/
          end
        end
      end

      rm(file)
      mv(file + ".new", file)
    end
  end
end
