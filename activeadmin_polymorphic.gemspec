$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "activeadmin_polymorphic/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.license     = "MIT"
  s.name        = "activeadmin_polymorphic"
  s.version     = ActiveadminPolymorphic::VERSION
  s.authors     = ["Petr Sergeev", "Sindre Moen"]
  s.email       = ["peter@hyper.no", "sindre@hyper.no"]
  s.description = 'This gem extends formtastic\'s form builder to support polymoprhic has many relations in your forms'
  s.summary     = 'HasMany polymoprhic support for active admin.'
  s.homepage    = "https://github.com/hyperoslo/activeadmin-polymorphic"

  s.files         = `git ls-files`.split("\n").sort
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
end
