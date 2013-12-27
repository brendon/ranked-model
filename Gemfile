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

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius-developer_tools'
end

# SQLite
gem "activerecord-jdbcsqlite3-adapter", ">= 1.3.0", platforms: :jruby
gem "sqlite3", platforms: :ruby

# Postgres
gem "activerecord-jdbcpostgresql-adapter", platforms: :jruby
gem "pg", platforms: :ruby

# MySQL
gem "activerecord-jdbcmysql-adapter", platforms: :jruby
gem "mysql", platforms: :ruby
