module ModelBuilder
  def self.included(base)
    base.send(:alias_method_chain, :method_missing, :model_builder) #unless base.instance_methods.include?("method_missing_with_model_builder")
  end

  def method_missing_with_model_builder(selector, *args)
    selector = selector.to_s
    if selector =~ /^build_/ then
      method = :new
    elsif selector =~ /^create_/ && selector.ends_with?("!") then
      method = :create!
    elsif selector =~ /^create_/ then
      method = :create
    elsif selector =~ /^params_/ then
      return send("hash_for_#{model_name_from_selector(selector)}", *args)
    else
      logger.warn "ModelBuilder did not recognize selector #{selector.inspect}"
      # It is important to call the super method with a symbolized version of the selector,
      # or else we'll get crashes with routes.  The routes are stored with interned (symbolized)
      # names.
      return method_missing_without_model_builder(selector.to_sym, *args)
    end

    model_name = model_name_from_selector(selector)
    attrs = send("hash_for_#{model_name}", *args)
    model_name.classify.constantize.send(method, attrs)
  end

  def model_name_from_selector(selector)
    selector = selector.to_s
    selector.sub(/^[^_]+_/, "").sub(/!$/, "")
  end

  def hash_for_workflow(attrs={})
    {:title => "Auto-Responder for Price List", :description => "Sends the price list, and does some stuff with it.", :creator => parties(:bob), :updator => parties(:bob), :account => parties(:bob).account}
  end

  def hash_for_step(attrs={})
    {:account => accounts(:wpul), :workflow => create_workflow, :model_class_name => "Party"}.merge(attrs)
  end

  def hash_for_trigger(attrs={})
    {:account => accounts(:wpul), :title => "All parties tagged X created in the past 20 days", :step => create_step}.merge(attrs)
  end

  def hash_for_task(attrs={})
    {:account => accounts(:wpul), :title => "Add tag Y", :step => create_step}.merge(attrs)
  end

  def hash_for_assignee(attrs={})
    {:account => accounts(:wpul), :party => parties(:bob), :task => create_task}.merge(attrs)
  end

  def hash_for_redirect(attrs={})
    {:fullslug => "/index.html", :target => "/", :creator => parties(:bob), :account => parties(:bob).account}.merge(attrs)
  end

  def hash_for_timeline(attrs={})
    {:subject => parties(:bob), :account => accounts(:wpul), :action => "update", :created_at => Time.now.utc}.merge(attrs)
  end

  def hash_for_party(attrs={})
    {:account => accounts(:wpul), :first_name => "Gandalf", :last_name => "The Grey"}.merge(attrs)
  end
  
  def hash_for_account(attrs={})
    {:expires_at => 5.years.from_now, :owner => parties(:bob)}
  end

  # Minimum attributes to successfully call Invoice.create!
  def hash_for_invoice(attrs={})
    {:date => Date.today, :invoice_to => parties(:bob), :account => accounts(:wpul)}.merge(attrs)
  end

  # Minimum attributes to POST /admin/invoices and be successful
  def params_for_invoice(attrs={})
    params = hash_for_invoice
    params[:invoice_to_id] = params.delete(:invoice_to).id
    params[:date] = params.delete(:date).to_s(:iso)
    params.merge(attrs).stringify_keys
  end

  def hash_for_estimate(attrs={})
    {:date => Date.today, :invoice_to => parties(:bob), :account => accounts(:wpul)}.merge(attrs)
  end

  def hash_for_order(attrs={})
    {:date => Date.today, :invoice_to => parties(:bob), :account => accounts(:wpul)}.merge(attrs)
  end

  def params_for_order(attrs={})
    params = hash_for_order
    params[:invoice_to_id] = params.delete(:invoice_to).id
    params[:date] = params.delete(:date).to_s(:iso)
    params.merge(attrs).stringify_keys
  end

  def params_for_estimate(attrs={})
    params = hash_for_order
    params[:invoice_to_id] = params.delete(:invoice_to).id
    params[:date] = params.delete(:date).to_s(:iso)
    params.merge(attrs).stringify_keys
  end
end
