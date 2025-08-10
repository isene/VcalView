require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Build the gem"
task :build do
  system "gem build calview.gemspec"
end

desc "Install the gem locally"
task :install => :build do
  system "gem install calview-*.gem"
end

desc "Clean up generated files"
task :clean do
  system "rm -f calview-*.gem"
end

desc "Run the calview script with a sample file"
task :run do
  if ENV['FILE']
    system "ruby bin/calview.rb #{ENV['FILE']}"
  else
    puts "Usage: rake run FILE=path/to/vcal/file"
  end
end