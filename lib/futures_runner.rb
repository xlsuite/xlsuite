#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FuturesRunner
  attr_accessor :running, :instance_id

  # A list of the 1st 10 prime numbers
  # Using prime numbers is a better way than hard-coding
  # the sleep time to a known value for all future runners.
  # Using prime numbers lowers the probability of having each
  # future runner trying to do something at the same time.
  SLEEP_TIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
  SMALL_SLEEP_TIMES = [2, 3]

  def self.start(instance_id=0)
    @runner = FuturesRunner.new(instance_id)
    self.install_signal_handlers
    @runner.start(self.select_random_sleep_time)
  end

  def self.select_random_sleep_time
    SLEEP_TIMES[rand(SLEEP_TIMES.length)]
  end
  
  def self.select_random_small_sleep_time
    SMALL_SLEEP_TIMES[rand(SMALL_SLEEP_TIMES.length)]
  end

  def self.install_signal_handlers
    Signal.trap("INT") { @runner.stop }
    Signal.trap("TERM") { @runner.stop }
  end

  def stop
    log "STOP requested"
    self.running = false
  end

  def initialize(instance_id)
    @instance_id = instance_id
    @running = true
    self.initialized!
  end

  def start(sleep_time)
    self.starting!(sleep_time)

    loop do
      break unless self.running?
      self.sleeping!
      sleep(sleep_time)
      break unless self.running?

      future = nil

      begin
        future = nil
        self.searching!
        if self.is_lock_free?
          self.acquire_lock do
            future = self.find_next_executable_runner
            future.update_attribute(:started_at, Time.now.utc) if future
          end
        else
          sleep(self.class.select_random_small_sleep_time)
          next
        end

        if future then
          if self.running? then
            begin
              self.running!(future)
              future.execute
            ensure
              self.done!(future)
            end
          else
            self.cancel!(future)
            future.update_attribute(:started_at, nil)
          end
        end
      rescue Object, Exception
        ExceptionNotifier.deliver_exception_caught($!, nil,
            :request => future ? OpenStruct.new(:parameters => future.args) : nil, :response => nil, :session => nil,
            :current_user => (future.owner rescue nil),
            :domain => (future.account.domains.find(:first) rescue nil),
            :account => (future.account rescue nil),
            :incoming_requests => nil)

        if $!.kind_of?(Future::LockError) then
          # Means either the connection is broken, or we were killed at the database level.
          # It is safer to quit than to try again.
          self.stop
          logger.warn { "Received a Future::LockError -- forcefully quitting" }
        end
      end
    end

    self.stopped!
  end

  def state_filename
    @state_filename ||= File.join(RAILS_ROOT, "log", "future-state-#{@instance_id}.log")
  end

  def running!(future)
    self.change_state!("RUNNING", future)
    log "RUNNING #{future.id}:#{future.class.name}\t#{future.args.inspect}"
  end

  def done!(future)
    self.change_state!("DONE", future)
    log "DONE #{future.id}:#{future.class.name}\t#{future.args.inspect}"
  end

  def cancel!(future)
    self.change_state!("CANCELLING", future)
    log "CANCELLING will not execute #{future.id}:#{future.class.name}"
  end

  def searching!
    self.change_state!("SEARCHING")
    debug "SEARCHING for work"
  end

  def sleeping!
    self.change_state!("SLEEPING")
    debug "SLEEPING"
  end

  def stopped!
    self.change_state!("STOPPED")
    log "STOPPED gracefully"
  end

  def starting!(sleep_time)
    self.change_state!("STARTING")
    log "STARTING sleep_time = #{sleep_time}"
  end

  def initialized!
    self.change_state!("INITIALIZED")
    log "INITIALIZED FuturesRunner in #{RAILS_ENV} environment"
  end

  def change_state!(new_state, future=nil)
    File.open(state_filename, "w") do |f|
      state = "#{ENV["FORGET_NAME"]}:#{instance_id}\t#{new_state}"
      state << "\t#{future.class.name}\t#{future.args.inspect}" if future
      f.puts state
    end
  end

  def running?
    @running
  end
  
  def is_lock_free?
    value = ActiveRecord::Base.connection.select_value("SELECT IS_FREE_LOCK('xlsuite.future-runner')")
    value == "1"
  end

  def acquire_lock
    Future.lock("xlsuite.future-runner") do
      yield
    end
  end

  def find_next_executable_runner
    Future.find_next_executable_runner
  end

  def debug(message)
    logger.debug {"#{Process.pid}:#{instance_id} - #{Time.now.utc.to_s(:iso)} - #{message}"}
  end

  def log(message)
    logger.info {"#{Process.pid}:#{instance_id} - #{Time.now.utc.to_s(:iso)} - #{message}"}
  end

  def logger
    @logger ||= RAILS_DEFAULT_LOGGER
  end
end
