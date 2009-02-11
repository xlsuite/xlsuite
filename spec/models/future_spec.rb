require File.dirname(__FILE__) + "/../spec_helper.rb"

describe Future, "#status!" do
  before do
    @future = Future.new
  end

  it "should update on disk immediately" do
    @future.status! :starting
    @future.reload.status.should == "starting"
  end

  it "should update the progress when passed a progress indicator" do
    @future.status! :collecting, 30
    @future.reload.progress.should == 30
  end

  it "should not update the progress when no progress indicator is sent" do
    @future.progress = 23
    @future.save(false)
    @future.status! :collecting
    @future.reload.progress.should == 23
  end
end

describe Future, "#execute (when interval is not nil)" do
  before do
    @future = Future.new(:interval => 2.minutes, :system => true)
    @future.stub!(:run)
    @future.save!
  end

  it "should duplicate itself when successfully executed" do
    original = Future.count
    @future.execute
    Future.should have(original + 1).records
  end
end

describe Future, "#return_to" do
  before do
    @future = Future.new
  end

  it "should return the #result_url unmodified" do
    @future.result_url = "/some-url?a=b"
    @future.return_to.should == @future.result_url
  end

  it "should replace '_id_' in the #result_url with the future's ID" do
    @future.save(false)
    @future.result_url = "/some-url/_id_?b=c"
    @future.return_to.should == "/some-url/#{@future.id}?b=c"
  end

  it "should return nil if #result_url is blank" do
    @future.return_to.should be_nil
  end
end

describe Future do
  before do
    @future = Future.new
  end

  it "should have an interval" do
    @future.interval = 3.hours
    @future.save(false)
    @future.reload.interval.should == 3.hours
  end

  it "should have an account" do
    lambda { @future.account = Account.find(:first) }.should_not raise_error
  end

  it "should be invalid if no account is set" do
    @future.should have(1).errors_on(:account_id)
  end

  it "should have an owner" do
    lambda { @future.owner = Party.find(:first) }.should_not raise_error
  end

  it "should be invalid if no owner is set" do
    @future.should have(1).errors_on(:owner_id)
  end

  it "should serialize #args in Hash form" do
    @future.args = {:a => "b"}
    @future.save(false)
    @future.reload.args.should == {:a => "b"}
  end

  it "should serialize #results in Hash form" do
    @future.results = {:c => "d"}
    @future.save(false)
    @future.reload.results.should == {:c => "d"}
  end

  it "should raise an error on #run! since it's supposed to be implemented by subclasses" do
    lambda { @future.run }.should raise_error(SubclassResponsibilityError)
  end

  it "should be possible to schedule a future" do
    @future.scheduled_at = 10.hours.from_now
    @future.save(false)
    @future.reload.scheduled_at == 10.hours.from_now
  end
end

describe Future, "where :system is true" do
  before do
    @future = Future.new(:system => true)
  end

  it "should be valid when no account is set" do
    @future.should have(:no).errors_on(:account_id)
  end

  it "should be valid when no owner is set" do
    @future.should have(:no).errors_on(:owner_id)
  end
end

describe Future, "#execute" do
  before do
    @future = Future.new(:system => true)
    @future.stub!(:run)
  end

  it "should set started_at when starting" do
    @future.started_at.should be_nil
    @future.execute
    @future.reload.started_at.should_not be_nil
  end

  it "should set ended_at upon returning" do
    @future.ended_at.should be_nil
    @future.execute
    @future.reload.ended_at.should_not be_nil
  end

  it "should set status to 'completed' when returning normally" do
    @future.execute
    @future.reload.status.should == "completed"
  end

  it "should return immediately if the future isn't scheduled to execute now" do
    @future.should_not_receive(:run)
    @future.scheduled_at = 1.minute.from_now
    @future.execute.should == false
    @future.status.should == "unstarted"
    @future.started_at.should be_nil
  end

  it "should set progress to 0 and status to 'initializing'" do
    @future.stub!(:status!)
    @future.should_receive(:status!).with(:initializing, 0)
    @future.execute
  end
end

describe Future, "#complete!" do
  before do
    @future = Future.new(:system => true)
    @future.stub!(:run)
    @future.complete!
  end

  it "should save the record" do
    @future.should_not be_new_record
  end

  it "should have a progress of 100%" do
    @future.progress.should == 100
  end

  it "should have a status of 'completed'" do
    @future.status.should == "completed"
  end

  it "should report itself as completed" do
    @future.should be_completed
  end

  it "should set the ended_at time" do
    @future.ended_at.should_not be_nil
  end
end

describe Future, "that has successfully executed and has a repeat interval" do
  before do
    @account = mock_account
    @owner = mock_party
    @future = Future.new(:interval => 2.minutes, :owner => @owner, :account => @account)
    @future.stub!(:run)
    @future.execute

    @other = Future.find(:first, :conditions => ["id > ?", @future])
  end

  it "should have set the status of the new future to 'unstarted'" do
    @other.status.should == "unstarted"
  end

  it "should have set the new future's started_at to nil" do
    @other.started_at.should be_nil
  end

  it "should have set the new future's progress to zero" do
    @other.progress.should be_zero
  end

  it "should have scheduled the new future to ended_at + interval" do
    @other.scheduled_at.to_s.should == (@future.ended_at + @future.interval).to_s
  end

  it "should have copied the owner" do
    @other.owner_id.should == @owner.id
  end

  it "should have copied the account" do
    @other.account_id.should == @account.id
  end
end

describe Future, "without an interval that has executed successfully" do
  before do
    @future = Future.new(:system => true)
    @future.stub!(:run)
    @future.save!
  end

  it "should not create a new future" do
    original = Future.count
    @future.execute
    Future.should have(original).records
  end
end

describe Future, "that fails to complete successfully" do
  before do
    @future = Future.new(:interval => 2.minutes, :system => true)
    @future.stub!(:run).and_raise(ArgumentError.new)
    @future.save!
  end

  it "should not create a new future" do
    original = Future.count
    @future.execute
    Future.should have(original).records
  end
end

describe Future, "#reschedule!" do
  before do
    @future = Future.create!(:system => true)
    @future.stub!(:run)
    @future.execute
    @future.reschedule!
  end

  it "should change the status back to 'unstarted'" do
    @future.status.should == "unstarted"
  end

  it "should change the progress back to 0" do
    @future.progress.should == 0
  end

  it "should set started_at to nil" do
    @future.started_at.should == nil
  end

  it "should set scheduled_at to nil" do
    @future.scheduled_at.should == nil
  end

  it "should set the results back to an empty Hash" do
    @future.results.should == {}
  end
end

describe Future, "#reschedule!(5.hours.from_now)" do
  before do
    @future = Future.create!(:system => true)
    @future.stub!(:run)
    @future.execute
    @future.reschedule!(5.hours.from_now)
  end

  it "should set scheduled_at to 5.hours.from_now" do
    @future.scheduled_at.to_s.should == 5.hours.from_now.to_s
  end
end

describe Future, "#execute when the subclass raises an exception" do
  before do
    @future = Future.new(:system => true)
    @future.stub!(:run).and_raise(@exception = ArgumentError.new)
    lambda { @future.execute }.should_not raise_error
    @future.reload
  end

  it "should set progress to 100" do
    @future.execute
    @future.reload.progress.should == 100
  end

  it "should change the status to 'error: <exception class name>'" do
    @future.status.should == "error: ArgumentError"
  end

  it "should add a new :error key in the results Hash" do
    @future.results[:error].should be_kind_of(Hash)
  end

  it "should repeat the exception class name in results[:error][:class]" do
    @future.results[:error][:class].should == @exception.class.name
  end

  it "should copy the exception's message in results[:error][:message]" do
    @future.results[:error][:message].should == @exception.message
  end

  it "should report the exception's backtrace in results[:error][:backtrace]" do
    @future.results[:error][:backtrace].should == @exception.backtrace
  end
end
