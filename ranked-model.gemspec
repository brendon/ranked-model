# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ranked-model/version"

Gem::Specification.new do |s|
  s.name        = "ranked-model"
  s.version     = RankedModel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Beale"]
  s.email       = ["matt.beale@madhatted.com"]
  s.homepage    = "https://github.com/harvesthq/ranked-model"
  s.summary     = %q{An acts_as_sortable replacement built for Rails 3}
  s.description = %q{ranked-model is a modern row sorting library built for Rails 3. It uses ARel aggressivly and is better optimized than most other libraries.}

  s.add_dependency "activerecord", ">= 3.0.3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "genspec"
  s.add_development_dependency "mocha"

  # s.rubyforge_project = "ranked-model"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
