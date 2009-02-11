module RedHillConsulting::CascadingStylesheets::ActionView::Helpers
  module AssetTagHelper
    def self.included(base)
      base.class_eval do
        alias_method_chain :stylesheet_link_tag, :cascade
      end
    end

    def stylesheet_link_tag_with_cascade(*sources)
      if sources.include?(:defaults)
        sources = sources.dup
        sources.delete(:defaults)

        candidates = controller.class.controller_path.split("/").inject([nil, nil, nil]) do |candidates, candidate|
          candidates << (candidates.last ? File.join(candidates.last, candidate) : candidate)
        end

        candidates[0] = "application"
        candidates[1] = RAILS_ENV
        candidates[2] = controller.controller_name
        candidates.insert(3, controller.active_layout) if controller.active_layout
        candidates << File.join(candidates.last, controller.action_name)

        candidates.each do |candidate|
          sources << candidate if File.exists?(File.join(RAILS_ROOT, "public/stylesheets", "#{candidate}.css"))
        end
      end

      stylesheet_link_tag_without_cascade(*sources.uniq)
    end
  end
end
