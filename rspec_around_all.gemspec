Gem::Specification.new do |s|
  s.name        = 'rspec_around_all'
  s.version     = '0.1.1'
  s.platform    = Gem::Platform::RUBY
  s.authors      = ['Myron Marston', 'Sean Walbran']
  s.email       = 'seanwalbran@gmail.com'
  s.homepage    = 'https://github.com/seanwalbran/rspec_around_all'
  s.summary     = 'Provides around(:all) hook for RSpec'
  s.license     = 'MIT'

  s.files         = Dir["{lib}/**/*"] + ['LICENSE', 'README.md']
  s.test_files     = Dir["{spec}/**/*"]
  s.require_paths  = ['lib']

  s.add_dependency 'rspec', "~> 2.0"

  s.required_ruby_version = '>= 1.9.2'
end

