# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "query_string_interface/version"

Gem::Specification.new do |s|
  s.name        = "query_string_interface"
  s.version     = QueryStringInterface::VERSION
  s.authors     = ["Vicente Mundim"]
  s.email       = ["vicente.mundim@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Extracts query string params to a structured data, suitable to use for model queries}
  s.description = %q{This gem extracts params given as a hash to structured data, that can be used when creating queries}

  s.rubyforge_project = "query_string_interface"

  s.add_runtime_dependency("activesupport", [">= 3.0.0"])

  s.add_development_dependency(%q<rspec>, [">= 2.6.0"])

  s.files = Dir.glob("lib/**/*") + %w(MIT_LICENSE README.md Gemfile Gemfile.lock)
  s.require_paths = ["lib"]
end
