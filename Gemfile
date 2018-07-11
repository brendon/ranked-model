source "https://rubygems.org"

# Specify your gem's dependencies in ranked-model.gemspec
gemspec

gem 'rubysl', '~> 2.0', platform: :rbx
gem 'rubinius-developer_tools', platform: :rbx

group :sqlite do
  gem "activerecord-jdbcsqlite3-adapter", ">= 1.3.0", platform: :jruby
  gem "sqlite3", platform: :ruby
end

group :mysql do
  gem "activerecord-jdbcmysql-adapter", platform: :jruby
end

group :postgresql do
  gem "activerecord-jdbcpostgresql-adapter", platform: :jruby
end