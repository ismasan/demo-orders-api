# frozen_string_literal: true
source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'sinatra'
gem 'puma'
gem 'parametric'
gem 'oat'
gem 'redis'
gem 'pusher'

group :development do
  gem 'foreman'
end

group :test do
  gem 'bootic_client'
  gem 'dotenv'
  gem 'rspec'
  gem 'rack-test'
  gem 'byebug'
end
