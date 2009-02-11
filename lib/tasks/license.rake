namespace :license do
  desc "Prepend LICENSE to all .rb files in app and lib"
  task :prepend do
    read_file = nil
    read_lines = []
    new_file = nil
    license_lines = []
    File.new("LICENSE").each_line do |line|
      license_lines << ("# " + line)
    end
    Dir["{app,lib}/**/*.rb"].each do |path|
      read_file = File.new(path)
      read_lines = []
      read_file.each_line do |line|
        read_lines << line
      end
      if (read_lines[0, license_lines.size] == license_lines)
        puts "License is already prepended to the file #{path}"
      else
        puts "Prepending license to file #{path}"
        new_file = File.new(path, "w")
        (license_lines + read_lines).each do |line|
          new_file.puts line
        end
        new_file.close
      end
    end
    puts "License successfully prepended to all .rb files under app and lib folders"
    nil
  end
end
