#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module DomainMatcher
  # Given an Array of Layout, Snippet or Page (self), returns the one
  # that best matches +domain+.
  def best_match_for_domain(domain)
    candidates = self.map do |obj|
      pattern = obj.patterns.detect {|pattern| domain.matches?(pattern)}
      [pattern, obj] if pattern
    end

    candidates.compact!

    case
    when candidates.empty?;     nil
    when candidates.size == 1;  candidates.first.last
    else
      # Order the candidates by the specificity of the pattern
      # ** is the lowest matching pattern: we use it only if nothing else matches
      # x.** or **.x is the second lowest matching pattern
      # x.*.com or *.com is better than nothing
      # but we really prefer: x.com (no wildcard)
      matches = candidates.sort_by do |pattern, page|
        case
        when pattern == "**"
          100
        when pattern.include?("**")
          50
        else
          pattern.gsub(/[^*]/, "").size
        end
      end

      matches.first.last
    end
  end
end

Array.send :include, DomainMatcher
