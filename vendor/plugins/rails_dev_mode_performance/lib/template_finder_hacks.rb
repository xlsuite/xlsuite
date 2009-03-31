module ActionView
  class TemplateFinder

  # make reload! impotent incase we're only using this patch
  class << self    
    def reload! 
    end
  end

  # if the template doesn't exist the first time we need to reload 
  # the view path cache and try again incase it's changed
  def file_exists_with_auto_reload?(path)
    result=file_exists_without_auto_reload?(path)
    unless result
      trigger_reload_of(view_paths)
      result=file_exists_without_auto_reload?(path)
    end
    result
  end
  alias_method_chain :file_exists?, :auto_reload  
  
  def trigger_reload_of(*view_paths)
    view_paths.each do |dir|
      @@processed_view_paths[dir] = []
      @@file_extension_cache[dir] = Hash.new {|hash, key| hash[key] = []}
    end
    self.view_paths=view_paths
  end
  
  # if a file that used to be in place can no longer be found
  # then we need to return false, which will coincidentally
  # force an auto-reload which will remove this bad data so
  # it won't befound next request cycle
  def find_base_path_for(template_file_name)
    p=@view_paths.find { |path| self.class.processed_view_paths[path].include?(template_file_name) }
    return p if p and File.exists?(File.join(p, template_file_name))
  end  
  
end
end