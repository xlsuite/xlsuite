require 'find'

Find.find('app/views') do |file|
  Find.prune if file =~ /\.svn/
  next unless file =~ /\.rhtml/
  changes = false
  File.open(file, 'rb') do |original|
    File.open("#{file}.new", 'wb') do |modified|
      while line = original.gets
        changes = true if line.gsub!("\t", '  ')
        modified.puts line
      end
    end
  end

  if changes then
    puts file
    File.rename(file, "#{file}.bak")
    File.rename("#{file}.new", file)
    File.unlink("#{file}.bak")
  else
    File.unlink("#{file}.new")
  end
end
