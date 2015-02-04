# Rails template to build the sample app for specs

run "rm Gemfile"
run "rm -r test"

# Create a cucumber database and environment
copy_file File.expand_path('../templates/cucumber.rb', __FILE__),                "config/environments/cucumber.rb"
copy_file File.expand_path('../templates/cucumber_with_reloading.rb', __FILE__), "config/environments/cucumber_with_reloading.rb"

gsub_file 'config/database.yml', /^test:.*\n/, "test: &test\n"
gsub_file 'config/database.yml', /\z/, "\ncucumber:\n  <<: *test\n  database: db/cucumber.sqlite3"
gsub_file 'config/database.yml', /\z/, "\ncucumber_with_reloading:\n  <<: *test\n  database: db/cucumber.sqlite3"

if File.exists? 'config/secrets.yml'
  gsub_file 'config/secrets.yml', /\z/, "\ncucumber:\n  secret_key_base: #{'o' * 128}"
  gsub_file 'config/secrets.yml', /\z/, "\ncucumber_with_reloading:\n  secret_key_base: #{'o' * 128}"
end


generate :model, "article title:string body:text --skip-unit-test"
inject_into_file "app/models/article.rb", %q{
  has_many :sections
  accepts_nested_attributes_for :sections
}, after: 'class Article < ActiveRecord::Base'

generate :model, "image image:string --skip-unit-test"
inject_into_file "app/models/image.rb", %q{
  has_many :sections
}, after: 'class Image < ActiveRecord::Base'

generate :model, "text body:string --skip-unit-test"
inject_into_file "app/models/text.rb", %q{
  has_many :sections
}, after: 'class Text < ActiveRecord::Base'

generate :model, "section article:belongs_to sectionable:belongs_to{polymorphic} position:integer"
inject_into_file "app/models/section.rb", %q{
    belongs_to :sectionable, polymorphic: true
    belongs_to :article
    accepts_nested_attributes_for :sectionable
}, after: 'class Section < ActiveRecord::Base'

# Configure default_url_options in test environment
inject_into_file "config/environments/test.rb", "  config.action_mailer.default_url_options = { host: 'example.com' }\n", after: "config.cache_classes = true\n"

# Add our local Active Admin to the load path
inject_into_file "config/environment.rb", "\n$LOAD_PATH.unshift('#{File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))}')\nrequire \"active_admin\"\n", after: "require File.expand_path('../application', __FILE__)"
#inject_into_file "config/application.rb", "\nrequire 'devise'\n", after: "require 'rails/all'"

# Force strong parameters to raise exceptions
inject_into_file 'config/application.rb', "\n\n    config.action_controller.action_on_unpermitted_parameters = :raise if Rails::VERSION::MAJOR == 4\n\n", after: 'class Application < Rails::Application'

# Add some translations
append_file "config/locales/en.yml", File.read(File.expand_path('../templates/en.yml', __FILE__))

# Add predefined admin resources
directory File.expand_path('../templates/admin', __FILE__), "app/admin"

# Add predefined policies
directory File.expand_path('../templates/policies', __FILE__), 'app/policies'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

generate 'active_admin:install --skip-users'

inject_into_file "config/routes.rb", "\n  root to: redirect('/admin')", after: /.*::Application.routes.draw do/
remove_file "public/index.html" if File.exists? "public/index.html"

# Devise master doesn't set up its secret key on Rails 4.1
# https://github.com/plataformatec/devise/issues/2554
# gsub_file 'config/initializers/devise.rb', /# config.secret_key =/, 'config.secret_key ='

rake "db:migrate db:test:prepare"
run "/usr/bin/env RAILS_ENV=cucumber rake db:migrate"

if ENV['INSTALL_PARALLEL']
  inject_into_file 'config/database.yml', "<%= ENV['TEST_ENV_NUMBER'] %>", after: 'test.sqlite3'
  inject_into_file 'config/database.yml', "<%= ENV['TEST_ENV_NUMBER'] %>", after: 'cucumber.sqlite3', force: true

  # Note: this is hack!
  # Somehow, calling parallel_tests tasks from Rails generator using Thor does not work ...
  # RAILS_ENV variable never makes it to parallel_tests tasks.
  # We need to call these tasks in the after set up hook in order to creates cucumber DBs + run migrations on test & cucumber DBs
  create_file 'lib/tasks/parallel.rake', %q{
namespace :parallel do
  def run_in_parallel(cmd, options)
    count = "-n #{options[:count]}" if options[:count]
    executable = 'parallel_test'
    command = "#{executable} --exec '#{cmd}' #{count} #{'--non-parallel' if options[:non_parallel]}"
    abort unless system(command)
  end

  desc "create cucumber databases via db:create --> parallel:create_cucumber_db[num_cpus]"
  task :create_cucumber_db, :count do |t, args|
    run_in_parallel("rake db:create RAILS_ENV=cucumber", args)
  end

  desc "load dumped schema for cucumber databases"
  task :load_schema_cucumber_db, :count do |t,args|
    run_in_parallel("rake db:schema:load RAILS_ENV=cucumber", args)
  end
end
}
end
