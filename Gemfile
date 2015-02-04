source 'https://rubygems.org'

gemspec

gem 'activeadmin', github: 'activeadmin'
gem 'inherited_resources'

group :development do
  # Debugging
  gem 'better_errors'      # Web UI to debug exceptions. Go to /__better_errors to access the latest one
  gem 'binding_of_caller'  # Retrieve the binding of a method's caller in MRI Ruby >= 1.9.2

  # Performance
  gem 'rack-mini-profiler' # Inline app profiler. See ?pp=help for options.
  gem 'flamegraph'         # Flamegraph visualiztion: ?pp=flamegraph

  # Documentation
  gem 'yard'               # Documentation generator
  gem 'redcarpet'          # Markdown implementation (for yard)
end

group :test do
  gem 'capybara'
  gem 'simplecov', require: false # Test coverage generator. Go to /coverage/ after running tests
  gem 'coveralls', require: false # Test coverage website. Go to https://coveralls.io
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'guard-rspec'
  gem 'jasmine'
  gem 'jslint_on_rails'
  gem 'launchy'
  gem 'rails-i18n' # Provides default i18n for many languages
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rspec-rails'
  gem 'i18n-spec'
  gem 'shoulda-matchers'
  gem 'sqlite3'
  gem 'poltergeist'
end
