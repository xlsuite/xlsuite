# these hacks are only for faster development
if RAILS_ENV=="development"
  # we need to load the rails dispatcher because normally it's not loaded so early
  require 'dispatcher'
  
  # these hacks kind of change everything around
  require 'dispatcher_hacks'
  require 'dep_hacks'
#  ActionView.eager_load_templates=false
  
  # for rails 2.1
  # require 'template_finder_hacks'
  # for rails 2.2
  require 'template_renderable_hacks'
end

