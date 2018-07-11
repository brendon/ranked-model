source "https://rubygems.org"

# Specify your gem's dependencies in ranked-model.gemspec
gemspec

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius-developer_tools'
end

group :sqlite do
  gem "activerecord-jdbcsqlite3-adapter", ">= 1.3.0", platforms: :jruby
  gem "sqlite3", platforms: [:ruby]
end

group :mysql do
  gem "activerecord-jdbcmysql-adapter", platforms: :jruby
end

group :postgresql do
  gem "activerecord-jdbcpostgresql-adapter", platforms: :jruby
end