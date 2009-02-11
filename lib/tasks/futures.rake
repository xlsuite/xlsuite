namespace :futures do
  task :scheduled => :environment do
    total_count = Future.count(:all, :conditions => "started_at IS NULL AND progress < 100")
    puts "#{total_count} futures are runnable, listing the first 100 or less"
    puts "="*80
    Future.find(:all, :conditions => "started_at IS NULL AND progress < 100", :order => "scheduled_at, priority, created_at", :limit => 100).each_with_index do |future, index|
      printf "%3d. %-23.23s %-20.20s %s\n", 1+index, "#{future.id}:#{future.class.name.sub('Future', '')}", future.scheduled_at < Time.now.utc ? "NOW" : future.scheduled_at.to_s(:db), future.args.empty? ? "" : future.args.inspect
    end
    puts
  end
end
