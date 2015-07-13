source 'https://rubygems.org'

gem 'rails', '~> 4.1.6'
gem 'mysql2'
gem 'devise'
gem "elasticsearch"
gem "elasticsearch-ruby"
gem "valium"
gem 'rmagick', '2.13.2', :require => false
gem 'aws-sdk'
gem 'whenever', :require => false
gem 'georuby', '2.2.1'
gem 'dbf', :require => 'dbf'
gem 'zip-zip'
gem 'rubyzip', :require => 'zip/zip'
gem "password_strength"
gem "ruby-recaptcha"
gem 'i18n-coffee'
gem 'rack-offline'

gem 'haml-rails', '~> 0.4'
gem 'gettext', '~> 3.1.2'
gem 'ruby_parser', :require => false, :group => :development
gem 'haml-magic-translations'
gem 'decent_exposure'
gem "instedd-rails", '~> 0.0.24'
gem "breadcrumbs_on_rails"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', '2.5.5', :require => 'resque_scheduler'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
gem 'jquery-rails', "~> 2.0.2"
gem 'foreman'
gem 'uuidtools'
gem 'newrelic_rpm'
gem 'cancancan', '~> 1.9'
gem 'carrierwave'
gem 'mini_magick'
gem 'includes-count'
gem 'poirot_rails', git: "https://github.com/instedd/poirot_rails.git", branch: 'master' unless ENV['CI']

gem 'treetop', '1.4.15'

gem 'protected_attributes'
gem 'rails-observers'
gem 'actionpack-page_caching'
gem "omniauth"
gem "omniauth-openid"
gem 'alto_guisso', github: "instedd/alto_guisso", branch: 'master'
gem 'alto_guisso_rails', github: "instedd/alto_guisso_rails", branch: 'master'
gem 'oj'
gem 'activerecord-import'
gem 'active_model_serializers'
gem 'actionpack-action_caching'
gem 'activerecord-deprecated_finders'

group :test do
  gem 'shoulda-matchers'
  gem 'ci_reporter', :git => 'git://github.com/nicksieger/ci_reporter.git'
  gem 'selenium-webdriver'
  gem 'nokogiri'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'resque_spec'
end

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'capistrano', '~> 2.15'
  gem 'rvm'
  gem 'rvm-capistrano', '1.2.2', :require => false
  gem 'jasminerice', '~> 0.1.0', :git => 'https://github.com/bradphelan/jasminerice'
  gem 'guard-jasmine'
  # gem 'pry'
  # gem 'pry-byebug'
  gem 'byebug'
  # gem 'pry-debugger', '~>0.2.2'
end

group :development do
  gem 'dist', :git => 'https://github.com/manastech/dist.git'
  gem 'ruby-prof', :git => 'https://github.com/ruby-prof/ruby-prof.git'
  gem 'mailcatcher'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'sass-rails',   '~> 4.0.1'
  gem 'coffee-rails', '~> 4.0.1'

  gem 'uglifier', '>= 2.5.0'
  gem 'lodash-rails'
end

gem 'rails_12factor', group: :production