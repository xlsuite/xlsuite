require "yaml"

RAILS_ROOT = ENV["RAILS_ROOT"] || "/var/www/xlsuite/current"
USER_DATA = YAML.load_file("/root/user_data.yml")
FORGET_NAME = USER_DATA[:name]

(5001 .. 5005).each do |port|
  pid_file = File.join(RAILS_ROOT, "log", "mongrel.#{port}.pid")

  God.watch do |w|
    w.group = "mongrels"
    w.name = "#{FORGET_NAME}-mongrel-#{port}"
    w.interval = 30.seconds
    w.start = "/usr/bin/mongrel_rails start --port #{port} --log #{RAILS_ROOT}/log/mongrel.#{port}.log --pid #{pid_file} --chdir #{RAILS_ROOT} --environment production --daemonize"
    w.stop = "/usr/bin/mongrel_rails stop --pid #{pid_file}"
    w.start_grace = 1.minute
    w.restart_grace = 2.minutes
    w.pid_file = pid_file

    # When we are ready, we can turn this on:
    # w.uid = 'deploy'
    # w.gid = 'deploy'

    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 220.megabytes
        c.times = [8, 10]
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end

    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end
