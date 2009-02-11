require "yaml"

RAILS_ROOT = ENV["RAILS_ROOT"] || "/var/www/xlsuite/current"
USER_DATA = YAML.load_file("/root/user_data.yml")
FORGET_NAME = USER_DATA[:name]

(0 .. 2).each do |instance|
  pid_file = File.join(RAILS_ROOT, "log", "futures_runner.#{instance}.pid")

  God.watch do |w|
    w.group = "futures_runners"
    w.name = "#{FORGET_NAME}-futures_runner-#{instance}"
    w.interval = 30.seconds
    w.start = "#{RAILS_ROOT}/script/futures_runner#{instance} start"
    w.stop = "#{RAILS_ROOT}/script/futures_runner#{instance} stop"
    w.start_grace = 4.minute
    w.restart_grace = 6.minutes
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
