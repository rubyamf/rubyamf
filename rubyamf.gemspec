# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rubyamf/version"

Gem::Specification.new do |s|
  s.name        = "rubyamf"
  s.version     = RubyAMF::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Augenstein"]
  s.email       = ["perl.programmer@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{AMF remoting for Ruby and Rails}
  s.description = %q{RubyAMF is an open source flash remoting gateway for Ruby on Rails and other Rack-based web frameworks.}
  s.rubyforge_project = "rubyamf"

  s.add_dependency('activesupport', '>= 2.3')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.has_rdoc         = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options     = ['--line-numbers', '--main', 'README.rdoc']
end
