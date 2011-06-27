require 'bundler'
require 'rspec/core/rake_task'
require 'rake/rdoctask'

g = Bundler::GemHelper.new(File.dirname(__FILE__))
g.install

RSpec::Core::RakeTask.new do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,gems']
end

desc 'Generate documentation for RubyAMF'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = g.gemspec.name
  rdoc.options += g.gemspec.rdoc_options
  rdoc.rdoc_files.include(*g.gemspec.extra_rdoc_files)
  rdoc.rdoc_files.include("lib") # Don't include ext folder because no one cares
end