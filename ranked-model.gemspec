# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ranked-model/version"

Gem::Specification.new do |s|
  s.name        = "ranked-model"
  s.version     = RankedModel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Beale"]
  s.email       = ["matt.beale@madhatted.com"]
  s.homepage    = "https://github.com/mixonic/ranked-model"
  s.summary     = %q{An acts_as_sortable replacement built for Rails 3 & 4}
  s.description = %q{ranked-model is a modern row sorting library built for Rails 3 & 4. It uses ARel aggressively and is better optimized than most other libraries.}
  s.license     = 'MIT'

  s.add_dependency "activerecord", ">= 4.1.16"
  s.add_development_dependency "rspec", "~> 3"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "mocha"
  s.add_development_dependency "database_cleaner", "~> 1.7.0"
  s.add_development_dependency "rake", "~> 10.1.0"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "pry"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
