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
  s.description = %q{ranked-model is a modern row sorting library built for Rails 3. It uses ARel aggressively and is better optimized than most other libraries.}

  s.add_dependency "activerecord", "~> 4.0.0.rc1"

  # NOTE cannot get rspec-rails to work without the following:
  s.add_development_dependency "railties", "~> 4.0.0.rc1"
  s.add_development_dependency "activesupport", "~> 4.0.0.rc1"
  s.add_development_dependency "actionpack", "~> 4.0.0.rc1"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.13.0"
  s.add_development_dependency "rspec-rails", "~> 2.13.1"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "genspec"
  s.add_development_dependency "mocha"

  # s.rubyforge_project = "ranked-model"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
