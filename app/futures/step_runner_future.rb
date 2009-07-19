#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class StepRunnerFuture < Future
  def run
    Step.find_next_runnable_steps.each do |step|
      begin
        step.run!
      rescue
        ExceptionNotifier.deliver_exception_caught($!, nil, :current_user => self.owner, :account => self.account, :request => OpenStruct.new(:parameters => self.args))
        next
      end
    end

    self.complete!
  end
end
