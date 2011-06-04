require 'bundler'
require 'spec/rake/spectask'
require 'rake/rdoctask'

g = Bundler::GemHelper.new(File.dirname(__FILE__))
g.install

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', 'spec/spec.opts']
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