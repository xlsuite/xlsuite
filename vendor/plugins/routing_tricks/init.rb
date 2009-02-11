require 'jamis_buck/routing/dsl'
require 'jamis_buck/routing/routeset'
require 'jamis_buck/routing/route'
require 'action_controller/routing'

ActionController::Routing::RouteSet::Mapper.send :include,
  JamisBuck::Routing::DSL::MapperExtensions

ActionController::Routing::RouteSet.send :include,
  JamisBuck::Routing::RouteSetExtensions

ActionController::Routing::Route.send :include,
  JamisBuck::Routing::RouteExtensions