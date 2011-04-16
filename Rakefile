require 'bundler'
require 'spec/rake/spectask'

Bundler::GemHelper.install_tasks

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', 'spec/spec.opts']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,gems']
end