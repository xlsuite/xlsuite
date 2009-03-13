#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class StepRunnerFuture < Future
  def run
    Step.find_next_runnable_steps.each do |step|
      MethodCallbackFuture.create!(:system => true, :method => :run!, :model => step)
    end

    self.complete!
  end
end
