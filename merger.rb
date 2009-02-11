require "fileutils"
require "yaml"

last_used_migration = Dir["db/migrate/*"].map {|f| File.basename(f)}.select {|m| m =~ /^\d{3}/}.sort.last[0,3].to_i

if ARGV.empty? then
  raise ArgumentError, "Need either --all or a list of revisions (124,156-168)"
elsif ARGV.include?("--all") then
  revisions = `svnmerge avail`.chomp
else
  revisions = ARGV.first
end

revisions.split(",").map do |rev|
  case rev
  when /-/
    start, finish = rev.split("-", 2)
    (start.to_i .. finish.to_i).to_a
  else
    rev.to_i
  end
end.flatten.each do |rev|
  puts "Merging r#{rev}..."
  merge = `svnmerge.py merge --force -r #{rev}`
  puts merge
  next if `svn st --ignore-externals | egrep -v ^X`.empty?

  merge.scan(%r{db/migrate/(\d{3}\w+\.rb)$}).sort.each do |migration|
    migration = migration.first
    info = YAML.load(`svn info db/migrate/#{migration}`)
    url, rev = info["Copied From URL"].chomp, info["Copied From Rev"]
    `svn revert db/migrate/#{migration}`
    FileUtils.rm("db/migrate/#{migration}")

    last_used_migration += 1
    new_migration = sprintf("%03d_%s", last_used_migration, migration[4..-1])
    `svn copy --revision #{rev} #{url} db/migrate/#{new_migration}`
    puts "Renamed #{migration} to #{new_migration}"
  end

  puts `svn resolved .`
  if merge =~ %r{^C\s+db/schema.rb} then
    puts `rake db:migrate`
    puts `svn resolved db/schema.rb`
  end

  if `svn st --ignore-externals` =~ /^(?:C|.C)/ then
    puts "Merge conflicts found"
    exit 1
  end

  puts `head svnmerge-commit-message.txt`
  puts `svn up --ignore-externals`
  puts `svn ci -F svnmerge-commit-message.txt`
  puts
end

puts "Done merging all changes"
exit 0
