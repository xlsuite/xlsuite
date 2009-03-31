ActionController::Dispatcher.class_eval do

  # Cleanup the application by clearing out loaded classes so they can
  # be reloaded on the next request without restarting the server.
  def cleanup_application
    # ActiveRecord::Base.reset_subclasses if defined?(ActiveRecord)
    # ActiveSupport::Dependencies.clear
    # ActiveRecord::Base.clear_reloadable_connections! if defined?(ActiveRecord)
  end
  
  def reload_application
   ActiveSupport::Dependencies.clear

    # Run prepare callbacks before every request in development mode
    run_callbacks :prepare_dispatch

    ActionController::Routing::Routes.reload
    # we don't need this because of template_renderable_hacks
#   ActionController::Base.view_paths.reload!
    # this doesn't seem to have a heavy performance penalty
    ActionView::Helpers::AssetTagHelper::AssetTag::Cache.clear
  end
  

end

