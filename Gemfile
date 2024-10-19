# frozen_string_literal: true

source "https://rubygems.org"

gem "pg", "~> 1.5"

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.21"

gem "rubocop-rspec", "~> 3.1.0"

if ENV["RAILS_VERSION"]
  gem "activerecord", ENV["RAILS_VERSION"]
  gem "activesupport", ENV["RAILS_VERSION"]
end

# Specify your gem's dependencies in active_record_proxy_adapters.gemspec
gemspec
