module JamisBuck
module Routing

  module RouteExtensions
    def self.included(base)
      base.alias_method_chain :recognition_conditions, :host
    end

    def recognition_conditions_with_host
      result = recognition_conditions_without_host
      result << "conditions[:host] === env[:host]" if conditions[:host]
      result << "conditions[:domain] === env[:domain]" if conditions[:domain]
      result << "conditions[:subdomain] === env[:subdomain]" if conditions[:subdomain]
      result
    end
  end

end
end