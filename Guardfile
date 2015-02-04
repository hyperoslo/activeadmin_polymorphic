# More info at https://github.com/guard/guard#readme

guard 'rspec', all_on_start: false, cmd: "bundle exec rspec" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/active_admin_polymorphic/(.+)\.rb$})     { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec/" }
  watch('spec/rails_helper.rb')  { "spec/" }
end
