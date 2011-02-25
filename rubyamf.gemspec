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
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "rubyamf"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
