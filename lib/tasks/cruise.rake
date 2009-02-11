
desc "CruiseControl.rb master task"
task :cruise => %w(cruise:db:reset cruise:run cruise:report) do
  raise "Some test failures or errors found" if $any_failures
end

namespace :cruise do
  namespace :db do
    task :reset => %w(environment db:migrate) do
      sh "svn revert db/development_structure.sql"
      Rake::Task["db:structure:dump"].invoke
    end
  end

  namespace :runtime do
    task :setup => :environment do
      $project_url = URI.parse(svn_info["URL"].chomp)
      $project_url.merge!("ci")
      $runtime_root = File.expand_path(File.join(RAILS_ROOT, "ci"))
      $runtime_path = File.join($runtime_root, "runtimes.yml")

      raise "No CC_BUILD_ARTIFACTS environment variable defined" if ENV["CC_BUILD_ARTIFACTS"].blank?
      $graph_root = File.expand_path(File.join(ENV["CC_BUILD_ARTIFACTS"], "graphs"))
      $graph_index = File.join($graph_root, "index.html")
      FileUtils.mkdir_p($graph_root)

      $coverage_path = File.expand_path(File.join(ENV["CC_BUILD_ARTIFACTS"], "coverage"))
      $aggregate_path = File.expand_path(File.join(RAILS_ROOT, "tmp", "coverage.info"))

      puts "Saving graphs to #{$graph_root}, coverage to #{$coverage_path} and runtime data to #{$runtime_root}"

      sh "svn checkout --quiet #{$project_url}"
      unless File.exist?($runtime_path)
        File.open($runtime_path, "wb") do |f|
          f.write([].to_yaml)
        end
      end
    end

    task :load => "cruise:runtime:setup" do
      $runtimes = if File.file?($runtime_path) then
        YAML::load(File.read($runtime_path)) || []
      else
        []
      end
    end

    task :record => "cruise:runtime:load" do
      $current_runtime, revision = {}, nil
      Tempfile.open("version") do |t|
        sh "svnversion . > #{t.path}"
        t.rewind
        revision = t.read.chomp.to_i
        $current_runtime[:date] = Time.now.utc
      end
      $runtimes << [revision, $current_runtime]
    end

    task :save => "cruise:runtime:setup" do
      File.open($runtime_path, "wb") do |f|
        f.puts $runtimes.to_yaml
      end
      sh "svn add --force --quiet #{$runtime_root}/*"
      sh %Q(svn commit #{$runtime_root} --message "Build Runtime Changes"), :noop => svn_no_commit?
    end
  end

  task :test => %w(cruise:runtime:record) do
    require "benchmark"
    $any_failures = false
    rm_f $aggregate_path
    testing_time = Benchmark.measure do
      %w(units functionals integration).each do |style|
        Tempfile.open("xlsuite-ci") do |t|
          sh "cd #{RAILS_ROOT} && rake 'RCOV_PARAMS=--output #{$coverage_path} --aggregate #{$aggregate_path} --sort coverage --no-html' test:#{style}:rcov > #{t.path} 2>&1" do |ok, res|
            $any_failures |= !res.success?
            accumulate_coverage_statistics(t)
          end
        end
      end
    end

    $current_runtime[:duration] = testing_time.real
  end

  namespace :report do
    task :setup => %w(cruise:runtime:load) do
      require "gruff"
    end

    task :base => "cruise:report:setup" do
      graph "Base Test Statistics", "base-stats.png" do |graph, runtimes|
        data = nil
        %w(failures errors).map(&:to_sym).each do |series|
          data = []
          runtimes.each do |revision, runtime|
            value = runtime[series] rescue 0
            data << [revision, value]
          end

          graph.data series, data.map(&:last)
        end

        data.each_with_index do |rev, index|
          next unless index == 0 || index % 3 == 0
          graph.labels[index] = rev.first.to_s 
        end

        graph.minimum_value = 0
      end
    end

    task :coverage => "cruise:report:setup" do
      graph "Global Test Coverage", "coverage-stats.png" do |graph, runtimes|
        data = nil
        %w(coverage).map(&:to_sym).each do |series|
          data = []
          runtimes.each do |revision, runtime|
            value = runtime[:files]["Total"][series] rescue 0
            data << [revision, value]
          end

          graph.data series, data.map(&:last)
        end

        data.each_with_index do |rev, index|
          next unless index == 0 || index % 3 == 0
          graph.labels[index] = rev.first.to_s 
        end

        graph.minimum_value, graph.maximum_value = 0, 100
      end
    end

    task :loc => "cruise:report:setup" do
      graph "Lines/LOC Statistics", "loc-stats.png" do |graph, runtimes|
        data = nil
        %w(loc lines).each do |series|
          data = []
          runtimes.each do |revision, runtime|
            value = runtime[:files]["Total"][series.to_sym] rescue 0
            data << [revision, value]
          end

          graph.data series, data.map(&:last)
        end

        data.each_with_index do |rev, index|
          next unless index == 0 || index % 3 == 0
          graph.labels[index] = rev.first.to_s 
        end
      end
    end

    task :runtime => "cruise:runtime:load" do
      graph "Total Runtime Statistics", "runtime-stats.png" do |graph, runtimes|
        data = nil
        %w(duration).each do |series|
          data = []
          runtimes.each do |revision, runtime|
            value = runtime[series.to_sym] rescue 0
            data << [revision, value]
          end

          graph.data series, data.map(&:last)
        end

        data.each_with_index do |rev, index|
          next unless index == 0 || index % 3 == 0
          graph.labels[index] = rev.first.to_s 
        end

        graph.minimum_value = 0
      end
    end

    task :html => "cruise:runtime:load" do
      require "erb"
      require "ostruct"
      report = File.read(File.join(RAILS_ROOT, "test", "index.html.erb"))
      revision = $runtimes.map(&:first).last || 0
      rt = $runtimes.assoc(revision).last || {}
      data = OpenStruct.new(:revision => revision,
                            :datetime => rt[:date] || Time.now.utc,
                            :runtime => rt[:duration] || 0)
      puts "Generating report using:\n#{data.inspect}"
      File.open($graph_index, "wb") do |f|
        f << ERB.new(report).result(data.send(:binding))
      end
    end

    task :generate => %w(cruise:report:coverage cruise:report:loc cruise:report:base cruise:report:runtime cruise:report:html)
  end

  desc "Generate full statistical reports"
  task :report => "cruise:report:generate"

  task :run => %w(cruise:test cruise:runtime:save)
end

def svn_no_commit?
  !ENV["CRUISE_NO_COMMIT"].blank?
end

def svn_info
  @info ||= Tempfile.open("svn") do |t|
    sh "svn info > #{t.path}"
    t.rewind
    return YAML::load(t.read)
  end
end

def graph(title, filename, options={})
  options.reverse_merge!(:width => 600, :type => Gruff::Line)
  puts "Generating #{title} graph"
  graph = options[:type].new(options[:width])
  graph.theme_rails_keynote

  # Grab only the latest 20 runtimes
  yield graph, $runtimes.last(20)

  filepath = File.join($graph_root, filename)
  puts "Writing #{filepath}"
  graph.title = title
  graph.write(filepath)
end

def accumulate_coverage_statistics(tempfile)
  tempfile.rewind
  lines = tempfile.read
  print lines

  tests, assertions, failures, errors = 0, 0, 0, 0
  lines.scan(/(\d+) tests/) do |count|
    tests += count.to_s.to_i
  end
  lines.scan(/(\d+) assertions/) do |count|
    assertions += count.to_s.to_i
  end
  lines.scan(/(\d+) failures/) do |count|
    failures += count.to_s.to_i
  end
  lines.scan(/(\d+) errors/) do |count|
    errors += count.to_s.to_i
  end

  $current_runtime[:tests] ||= 0
  $current_runtime[:assertions] ||= 0
  $current_runtime[:failures] ||= 0
  $current_runtime[:errors] ||= 0
  $current_runtime[:tests] += tests
  $current_runtime[:assertions] += assertions
  $current_runtime[:failures] += failures
  $current_runtime[:errors] += errors

  $current_runtime[:files] = Hash.new
  lines.scan(%r{^[|]([\w./]+)\s*[|]\s*(\d+)\s[|]\s*(\d+)\s[|]\s*([\d.]+)%\s[|]}) do |filename, lines, loc, coverage|
    $current_runtime[:files][filename] ||= {:lines => 0, :loc => 0, :coverage => 0.0}
    $current_runtime[:files][filename][:lines] = lines.to_i
    $current_runtime[:files][filename][:loc] = loc.to_i
    cov = [coverage, $current_runtime[:files][filename][:coverage]].map(&:to_f).reject(&:zero?)
    $current_runtime[:files][filename][:coverage] = cov.sum / cov.size
  end

  lines, locs, coverage = 0, 0, []
  $current_runtime[:files].each_pair do |filename, attrs|
    lines += attrs[:lines]
    locs += attrs[:loc]
    coverage << attrs[:coverage]
  end
  $current_runtime[:files]["Total"] = {:lines => lines, :loc => locs, :coverage => coverage.sum / coverage.size.to_f}
end
