require "bundler/gem_tasks"

desc "Open a pry console preloaded with this library"
task console: 'console:pry'

namespace :console do

  task :pry do
    sh "bundle exec pry -I lib -r clientele.rb"
  end

  task :irb do
    sh "bundle exec irb -I lib -r clientele.rb"
  end

end
