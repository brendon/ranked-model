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

  s.add_dependency "activerecord", ">= 3.1.12"
  s.add_development_dependency "rspec", "~> 2.13.0"
  s.add_development_dependency "sqlite3", "~> 1.3.7"
  s.add_development_dependency "genspec", "~> 0.2.8"
  s.add_development_dependency "mocha", "~> 0.14.0"
  s.add_development_dependency "database_cleaner", "~> 1.2.0"
  s.add_development_dependency "rake", "~> 10.1.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
