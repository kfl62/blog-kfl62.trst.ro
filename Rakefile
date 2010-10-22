require 'rack'
require 'thin'
require 'bundler/setup'
require 'nanoc3/tasks'
require 'nanoc3/cli'
require 'compass'
Compass.add_project_configuration('./lib/compass.rb')

desc "Runs autocompile/preview"
task :preview do
  # Run base
  Nanoc3::CLI::Base.shared_base.run(["autocompile","--handler=thin"])
end

desc "Runs compile/generate"
task :build do
  # Run base
  Nanoc3::CLI::Base.shared_base.run(["compile"])
end

