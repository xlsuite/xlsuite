puts IO.read(File.join(File.dirname(__FILE__), 'README'))

File.open(File.join(File.dirname(__FILE__), 'tasks/s3.rake'), 'r') do |file|
  past_intro = false
  file.each do |line|
    past_intro = true if line.split.first != '#'
    puts line unless past_intro
  end
end

copy_config = "cp #{File.join(File.dirname(__FILE__), 'config/s3.yml')} #{File.dirname(__FILE__)}/../../../config/s3.yml"
puts "installing s3.yml config file:"
puts copy_config
system(copy_config)

puts ""
puts "you should now update your config/s3.yml file with your AWS credentials"
