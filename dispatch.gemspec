# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dispatch/version"

Gem::Specification.new do |s|
  s.name        = "dispatch"
  s.version     = Dispatch::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Arthur Gunn"]
  s.email       = ["arthur@gunn.co.nz"]
  s.homepage    = "https://github.com/gunn/dispatch"
  s.summary     = %q{Dispatch is a MacRuby wrapper around Mac OS X's Grand Central Dispatch.}
  s.description = %q{Grand Central Dispatch is natively implemented as a C API and runtime engine. This gem provides a MacRuby wrapper around that API and allows Ruby to very easily take advantage of GCD to run tasks in parrallel and do calculations asynchronously with queues automatically mapping to threads as needed.}

  s.rubyforge_project = "dispatch"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
