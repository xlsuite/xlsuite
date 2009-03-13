#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MethodCallbackFuture < Future
  attr_writer :method
  attr_accessor :params

  validate :presence_of_model_class
  validate :presence_of_method
  validate :homogenous_models_collection

  before_create :set_callback_args

  def run
    status!(:initializing, 0)
    if self.args[:class_name].blank?
      status!(:error)
      self.update_attribute(:results, ":class_name can't be blank")
      return
    end
    models_size = models.size
    i = 0
    completed = models.map do |model|
      begin
        return_value = false
        self.class.lock("MCF-#{model.class.name}-#{model.id}-#{args[:method]}") do
          if self.args.has_key?(:params) then
            return_value = model.send(self.args[:method], Marshal.load(Marshal.dump(self.args[:params])))     
          else
            return_value = model.send(self.args[:method])
          end
        end
        i+=1

        status!(:processing, i/models_size * 90)
        return_value
      rescue Future::RetryCountExceeded
        # NOP: it might be normal to get this exception if some other process
        # is running another MethodCallbackFuture exactly the same as this one.
        # Just ignore for now, but log for reference purposes
        logger.warn("#{$!.class.name}: #{$!.message} while trying to execute #{model.class.name}:#{model.id}\##{args[:method]}")
        false
      end
    end

    if repeat_until_true then
      if completed.all? then
        self.complete!
      else
        status!(:unstarted, 0)
        self.update_attributes!(:started_at => nil, :scheduled_at => 1.minute.from_now)
      end
    else
      self.complete!
    end
  end

  def model=(model)
    self.models = [model]
  end

  def model
    self.models.first
  end

  def models=(models)
    @models = models
  end

  def model_class
    self.args[:class_name].constantize
  end

  def models
    model_class.find(self.args[:ids])
  end

  def method
    self.args[:method]
  end

  def repeat_until_true
    self.args[:repeat_until_true] || false
  end

  def repeat_until_true=(value)
    self.args[:repeat_until_true] = value
  end

  protected
  def flattenized_models
    (@models || []).flatten.compact
  end

  def set_callback_args
    self.args[:ids] = flattenized_models.map(&:id)
    self.args[:class_name] = flattenized_models.map(&:class).uniq.map(&:name).first
    self.args[:method] = @method.to_s
    self.args[:params] = @params unless @params.blank?
  end

  def homogenous_models_collection?
    flattenized_models.map(&:class).uniq.length <= 1
  end

  def homogenous_models_collection
    self.errors.add(:models, "must contain a single type of object, found #{flattenized_models.map(&:class).uniq.map(&:name).to_sentence}") \
      unless homogenous_models_collection?
  end

  def presence_of_model_class
    self.errors.add(:models, "can't be blank") if flattenized_models.map(&:class).uniq.map(&:name).blank? && self.args[:class_name].blank?
  end

  def presence_of_method
    self.errors.add(:method, "can't be blank") if @method.blank? && self.args[:method].blank?
  end

  def owner_required?
    false
  end
end
