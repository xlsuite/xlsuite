module JamisBuck
module Routing

  # A custom controller that we'll use for routing trickiness.
  class TricksController < ActionController::Base

    # A simple action that simple accepts a destination route, and emits a
    # redirect to it.
    def do_redirect
      params.delete(:controller)
      params.delete(:action)
      route = params.delete(:destination)

      redirect_to send(:"#{route}_url", params)
    end

  end

  module DSL
    module MapperExtensions

      # The implementation of the "redirect" DSL syntax. It takes a path
      # string, and a destination symbol naming the route to redirect to.
      # Any additional options are merged into the route definition and will
      # be passed to the destination route.
      def redirect(path, destination, options={})
        options = options.merge(:controller => "jamis_buck/routing/tricks",
          :action => "do_redirect", :destination => destination)
        @set.add_route(path, options)
      end

    end
  end

end
end