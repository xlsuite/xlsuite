module XlSuite
  extend self

  def version
    @__xlsuite_version ||=
        case
        when File.directory?(RAILS_ROOT + "/.git")
          `cd #{RAILS_ROOT} && git log -n 1 --pretty=short | grep commit | awk '{ print $2 }'`.chomp
        when File.directory?(RAILS_ROOT + "/.svn")
          `svnversion #{RAILS_ROOT}`
        when File.file?(RAILS_ROOT + "/REVISION")
          File.read(RAILS_ROOT + "/REVISION")
        else
          "development"
        end
  end
end
