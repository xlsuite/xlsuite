module RedHillConsulting::CascadingJavascripts::ActionView::Helpers
  module AssetTagHelper
    def self.included(base)
      base.class_eval do
        alias_method_chain :javascript_include_tag, :cascade
      end
    end

    def javascript_include_tag_with_cascade(*sources)
      if sources.include?(:defaults)
        ["#{@controller.controller_name}", "#{@controller.controller_name}/#{@controller.action_name}"].each do |source|
          sources << source if File.exists?("#{RAILS_ROOT}/public/javascripts/#{source}.js")
        end
      end

      javascript_include_tag_without_cascade(*sources.uniq)
    end
  end
end
