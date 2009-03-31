module ActionView #:nodoc:
  
  class Base
    
    def _pick_template_with_file_exists(template_path)
      template=_pick_template_without_file_exists(template_path)
      # call into the template just to make sure it's still there
      # and if not give it a chance to raise MissingTemplate
      template.file_changed?
      template
    end
    alias_method_chain :_pick_template, :file_exists
  end
  
  class Template
    
    attr_accessor :last_modified
    
    def source
      @last_modified=File.stat(filename).mtime
      File.read(filename)
    end

    def freeze
      # we don't want to be frozen
      self
    end
    
    def file_changed?
      raise MissingTemplate.new([load_path], File.basename(filename)) unless File.exists?(filename)
      @last_modified.nil? or File.stat(filename).mtime > @last_modified
    end
    
    def render_template_with_reset(*args)
      if file_changed?
        ["source","compiled_source"].each do |attr|          
          ivar=ActiveSupport::Memoizable::MEMOIZED_IVAR.call(attr)
          instance_variable_get(ivar).clear if instance_variable_defined?(ivar)
        end
      end
      render_template_without_reset(*args)
    end
    
    alias_method_chain :render_template, :reset

  end
end