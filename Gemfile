source "https://rubygems.org"

# Specify your gem's dependencies in ranked-model.gemspec
gemspec

ar_version = ENV["ACTIVERECORD_VERSION"] || "default"

ar_gem_version = case ar_version
when "master"
  gem "activerecord", {github: "rails/rails"}
when "default"
  # Allow the gemspec to specify
else
  gem "activerecord", "~> #{ar_version}"
end
