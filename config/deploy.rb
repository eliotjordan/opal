# config valid only for current version of Capistrano
lock '3.6.1'

set :application, 'opal'
set :repo_url, 'https://github.com/eliotjordan/opal.git'

# Default branch is :master
set :branch, ENV['BRANCH'] || 'master'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/opt/opal'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/blacklight.yml',
                                                 'config/database.yml',
                                                 'config/secrets.yml',
                                                 'config/fedora.yml',
                                                 'config/solr.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/derivatives', 'tmp/uploads', 'vendor/bundle', 'staged_files')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Default value for keep_releases is 5
# set :keep_releases, 5
set :passenger_restart_with_sudo, true

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end

namespace :sidekiq do
  task :quiet do
    on roles(:worker) do
      # Horrible hack to get PID without having to use terrible PID files
      puts capture("kill -USR1 $(sudo initctl status opal-workers | grep /running | awk '{print $NF}') || :")
      puts capture("kill -USR1 $(sudo initctl status opal-derivatives | grep /running | awk '{print $NF}') || :")
    end
  end
  task :restart do
    on roles(:worker) do
      execute :sudo, :initctl, :restart, 'opal-workers'
      execute :sudo, :initctl, :restart, 'opal-derivatives'
    end
  end
end
after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:published', 'sidekiq:restart'
