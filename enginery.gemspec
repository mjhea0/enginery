# encoding: UTF-8

require File.expand_path('../lib/enginery/version', __FILE__)
Gem::Specification.new do |s|

  s.name = 'enginery'
  s.version = EngineryVersion::FULL
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'https://github.com/espresso/enginery'
  s.summary = 'enginery-%s' % EngineryVersion::FULL
  s.description = 'Stuff Builder for Espresso Framework'

  s.required_ruby_version = '>= 1.9.2'
  
  s.add_dependency 'e',    '>= 0.4.8'
  s.add_dependency 'el',   '>= 0.4.8'
  s.add_dependency 'rear', '>= 0.1.0'
  s.add_dependency 'bundler'
  s.add_dependency 'tenjin'

  s.add_development_dependency 'bundler'

  s.require_paths = ['lib']
  s.files = Dir['**/{*,.[a-z]*}'].reject {|e| e =~ /\.(gem|lock)\Z/}
  s.executables = ['enginery']
  s.licenses = ['MIT']
end
