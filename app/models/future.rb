#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "ostruct"

# We can't wrap #execute in a transaction, or else nothing outside of the
# current process will see the progress and status.  That's transaction
# isolation.
class Future < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id, :if => proc {|r| !r.system?}

  belongs_to :owner, :class_name => "Party", :foreign_key => :owner_id
  validates_presence_of :owner_id, :if => :owner_required?

  serialize :args
  serialize :results

  validates_numericality_of :progress
  validates_inclusion_of :progress, :within => (0 .. 100)
  before_validation {|f| f.progress = 0 if f.progress < 0; f.progress = 100 if f.progress > 100}

  COMPLETED_STATUS = "completed"
  ERRORED_STATUS = "error"

  def args
    read_attribute(:args) || write_attribute(:args, Hash.new)
  end
  
  def results
    read_attribute(:results) || write_attribute(:results, Hash.new)
  end

  def return_to
    return nil if self.result_url.blank?
    self.result_url.to_s.gsub("_id_", self.id.to_s)
  end

  def status!(new_status, progress = nil)
    return if self.status == new_status.to_s && self.progress == progress
    self.status = new_status.to_s
    self.progress = progress || self.progress
    self.save(false) # Don't run validation
  end

  def reschedule!(time=nil)
    self.update_attributes!(:results => {}, :status => "unstarted", :progress => 0, 
        :started_at => nil, :scheduled_at => time)
  end

  def execute
    logger.debug {"#{self.class.name}\#execute:#{self.id} (scheduled_at => #{self.scheduled_at}"}
    return false if self.scheduled_at && self.scheduled_at > Time.now
    self.update_attribute(:started_at, Time.now)

    # Reset our results to an empty Hash, to prevent NoMethodError #[] on NilClass.
    # This replaces the old #set_default_values callback
    self.results = Hash.new

    begin
      self.run
    rescue Object, Exception
      logger.warn {"Caught exception while processing #{self.class.name}:#{self.id}\n#{$!}\n#{$!.backtrace.join("\n")}"}
      ExceptionNotifier.deliver_exception_caught($!, nil, :current_user => self.owner, :account => self.account, :request => OpenStruct.new(:parameters => self.args))
      self.update_attributes!(:status => "#{ERRORED_STATUS}: #{$!.class.name}", :results => self.results.merge(:error => {:at => Time.now.utc, :class_name => $!.class.name,
          :backtrace => $!.backtrace, :message => $!.message}), :progress => 100, :ended_at => Time.now.utc)
    end
  end

  def execute_with_interval
    begin
      execute_without_interval
    ensure
      # If it needs to be rescheduled
      if (!self.interval.blank?)
        # If the future completed normally, reschedule itself
        if (self.completed?)
          self.reschedule!(self.ended_at + self.interval) 
        # If it errored and it's not a RetsSearchFuture, or for whatever reason a system future did not 
        # complete normally, reschedule a duplicate of itself
        elsif (self.errored? and !(self.class.name =~ /RetsSearchFuture/i) || self.system?)
          other = self.class.new(self.attributes)
          other.reschedule!(self.ended_at + self.interval)
        end
      end
    end
  end

  alias_method_chain :execute, :interval

  def run
    raise SubclassResponsibilityError, "#run! should be implemented in subclasses"
  end

  def complete!
    self.status = COMPLETED_STATUS
    self.progress = 100
    self.ended_at = Time.now.utc
    self.save!
  end

  def completed?
    self.status == COMPLETED_STATUS
  end

  def done?
    completed? || errored? || (self.interval && self.ended_at && (self.scheduled_at > self.ended_at))
  end

  def errored?
    self.status[ERRORED_STATUS] ? true : false
  end
  
  def ==(other)
    other.kind_of?(self.class) &&
    self.account_id == other.account_id &&
    self.owner_id == other.owner_id &&
    self.autoclean == other.autoclean &&
    self.args == other.args &&
    self.system == other.system &&
    self.priority == other.priority &&
    self.interval == other.interval
  end

  class LockError < RuntimeError; end
  class RetryCountExceeded < LockError; end

  class << self
    def get_status_of(ids)
      future_ids = case ids
        when String
         ids.split(",")
        when Array
         ids
        end
      futures = Future.all(:conditions => ["id in (?)", future_ids])
      return status = {
        'ids' => futures.map(&:id),
        'startedAt' => futures.map(&:started_at).compact.sort.first,
        'progress' => Float(futures.map(&:progress).reject{|f|f.nil?}.inject{|sum, n|sum+n})/Float(futures.size),
        'isCompleted' => futures.map(&:done?).uniq == [true],
        'errors' => [futures.map{|f|f.results[:error]}].compact
      }
    end
    
    # This implementation is MySQL 5 specific.
    def lock(lock_name, options={})
      raise ArgumentError, "Must have a block to yield to" unless block_given?
      options.reverse_merge!(:retry_count => 3, :timeout => 2)

      options[:retry_count].times do
        case lock_value = connection.select_value("SELECT GET_LOCK(#{quote_value(lock_name)}, #{quote_value(options[:timeout])})")
        when "1"
          # Got lock
          begin
            return yield
          ensure
            connection.select_value("SELECT RELEASE_LOCK(#{quote_value(lock_name)})")
          end

        when "0"
          # Failed to acquire lock
          logger.warn {"Failed to acquire #{lock_name.inspect} -- try again"}
          sleep(rand() * options[:timeout])  # Add a random amount of sleeping
                                          # so conflicting processes may gracefully
                                          # get the lock
        else
          # Error during locking
          raise LockError, "Failed to acquire lock because MySQL returned #{lock_value.inspect}"
        end
      end

      raise RetryCountExceeded, "Could not get lock #{lock_name.inspect} with #{options[:timeout]}s timeout within #{options[:retry_count]} attempts."

      rescue Mysql::Error, ActiveRecord::StatementInvalid
        raise LockError, "#{$!.class.name}:  #{$!.message}\n#{$!.backtrace.join("\n")}"
    end

    def find_next_executable_runner
      now = Time.now.utc
      find(:first, :conditions => ["scheduled_at < ? AND started_at IS NULL AND progress < 100", now], :order => "priority, scheduled_at, created_at")
    end
  end

  protected
  def owner_required?
    !self.system?
  end
end
