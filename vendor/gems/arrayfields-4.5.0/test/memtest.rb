require 'lib/arrayfields'
STDOUT.sync = true

n = Integer((ARGV.shift or (2 ** 16)))

#
# hash mem usage - around 13016 on my machine
#
  fork do
    a = []
    n.times do  
      a << {'a' => 0, 'b' => 1, 'c' => 2}
    end

    puts "pid <#{ Process.pid }>"
    print "run top to examine mem usage of <#{ n }> hashes (enter when done) >"
    STDIN.gets
  end
  Process.wait


#
# arrayfields mem usage - around 8752 on my machine
#
  fork do
    fields = %w( a b c )
    a = []
    n.times do  
      t = [0,1,2]
      t.fields = fields
      t.extend ArrayFields
      a << [0,1,2]
    end

    puts "pid <#{ Process.pid }>"
    print "run top to examine mem usage of <#{ n }> extended arrays (enter when done) >"
    STDIN.gets
  end
  Process.wait
