namespace :license do
  desc "Prepend LICENSE to all .rb files in app and lib"
  task :prepend do
    require 'mmcopyrights'
    %w(app lib).each do |dir|
      MM::Copyrights.process(dir, "rb", "#-", "XLsuite, an integrated CMS, CRM and ERP for medium businesses\nCopyright 2005-#{Date.today.year} iXLd Media Inc.")
    end
  end
end
