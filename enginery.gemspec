# encoding: UTF-8

version = "0.0.1"
Gem::Specification.new do |s|

  s.name = 'enginery'
  s.version = version
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'https://github.com/espresso/enginery'
  s.summary = 'enginery-%s' % version
  s.description = 'Fine-Tuned App Builder for Espresso Framework'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'e', '>= 0.4.2'

  s.require_paths = ['lib']
  s.files = Dir['**/{*,.[a-z]*}'].reject {|e| e =~ /\.(gem|lock)\Z/}
  s.executables = ['enginery']

  s.licenses = ['MIT']
end
