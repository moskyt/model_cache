require 'rubygems' unless defined?(Gem)
s = Gem::Specification.new do |s|
  s.name = "model-cache"
  s.version = "0.2.1"
  s.summary = "Rails plugin for caching in models."
  s.author = "Frantisek Havluj"
  s.email = "moskyt@rozhled.cz"
  s.homepage = "http://github.com/moskyt/model_cache"
  s.has_rdoc = false
 
  s.files = Dir['lib/**/*'] + %w{
    init.rb
    README.textile
    MIT-LICENSE
    CHANGELOG
  }
   
  # s.extensions << 'extconf.rb'
  # s.test_file = 'test.rb'
end