# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "xlsuite"
set :repository, "https://svn.xlsuite.org/internal/weputuplights.com/branches/xlsuite-stable"

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :web, "xlsuite.teksol.info"
role :app, "xlsuite.teksol.info"
role :db,  "xlsuite.teksol.info", :primary => true

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, "/usr/local/www/xlsuite.com" # defaults to "/u/apps/#{application}"
set :user, "xlsuite"            # defaults to the currently logged in user
# set :scm, :darcs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway

set :use_sudo, false

# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:keys] = %w(~/.ssh/xlsuite@xlsuite.teksol.info.rsa)
ssh_options[:port] = 7501

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

task :after_update_code do
  run <<CMD
ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml && \
ln -nfs #{shared_path}/s3.yml #{release_path}/config/s3.yml && \
ln -nfs #{shared_path}/ferret_server.yml #{release_path}/config/ferret_server.yml && \
mkdir -p -m 0755 #{shared_path} #{shared_path}/attachments #{shared_path}/pictures #{shared_path}/index && \
ln -nfs #{shared_path}/attachments #{release_path}/attachments && \
ln -nfs #{shared_path}/index #{release_path}/index && \
ln -nfs #{shared_path}/pictures #{release_path}/public/pictures
CMD
end

task :restart do
  run <<CMD
cd #{current_path} && \
bin/mongrel restart 23241 xlsuite xlsuite && \
bin/mongrel restart 23242 xlsuite xlsuite && \
bin/ferret restart 23240 && \
script/daemons stop && \
script/wait_for_daemons 120 && \
RAILS_ENV=production script/daemons start
CMD
end

task :before_deploy do
  status = `svn st --ignore-externals`
  new_status = status.split("\n").reject do |line|
    line =~ /^\?/
  end
  unless new_status.empty? then
    puts '*'*60
    puts new_status.join("\n")
    puts '*'*60
    print "Uncommitted local changes.  Are you sure you want to deploy ? (y/N)"
    answer = $stdin.gets
    exit(1) unless answer =~ /y/i
  end
end

require 'uri'
task :after_deploy do
  source = repository
  dest = URI.parse(repository).merge("../releases/#{File.basename(release_path)}")
  cmd = "svn copy --revision=#{revision} --quiet --message \"Auto tagging release #{release_path}\" #{source} #{dest}"
  puts cmd
  `#{cmd}`
end

task :before_migrate do
  disable_web
end

task :after_migrate do
  enable_web
end

desc "tail production log files"
task :tail_logs, :roles => :app do
  run "tail -f #{shared_path}/log/production.log" do |channel, stream, data|
    puts  # for an extra line break before the host name
    puts "#{channel[:host]}: #{data}"
    break if stream == :err
  end
end

desc "remotely console"
task :console, :roles => :app do
  input = ''
  run "cd #{current_path} && ./script/console #{ENV['RAILS_ENV']}" do |channel, stream, data|
    next if data.chomp == input.chomp || data.chomp == ''
    print data
    channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
  end
end
