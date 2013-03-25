module Enginery
  module Test
    module ModelGenerator
      Spec.new self do

        Dir.chdir DST_ROOT do
          Testing do

            is(new_app 'App').ok?

            Dir.chdir 'App' do

              Should 'generate a plain class cause no setups given' do
                is(new_model 'Foo').ok?

                file = 'base/models/foo.rb'
                is(File).file? file
                expect(File.read file) =~ /class\s+Foo\n/
              end

              Should 'correctly handle namespaces' do
                is(new_model 'A::B::C').ok?

                file = 'base/models/a/b/c.rb'
                is(File).file? file
                code = File.read(file)
                expect(code) =~ /module A/
                expect(code) =~ /module B/
                expect(code) =~ /class C/
              end

            end
          end
          cleanup

          Should 'use ORM defined at project generation' do
            is(new_app 'App orm:DataMapper').ok?

            Dir.chdir 'App' do
              is(new_model 'Foo').ok?

              file = 'base/models/foo.rb'
              is(File).file? file
              source_code = File.read file
              does(source_code) =~ /class\s+Foo/
              does(source_code) =~ /include\s+DataMapper/

              Should 'include modules provided via include: option' do
                is(new_model 'Bar i:Rack::Utils').ok?

                file = 'base/models/bar.rb'
                is(File).file? file
                does(File.read file) =~ /include Rack::Utils/
              end
            end
          end
          cleanup

          Should 'create multiple models' do
            is(new_app 'App o:ar').ok?
            
            Dir.chdir 'App' do
              are(new_models 'A B C  X::Y::Z').ok?

              %w[a b c].each do |c|
                file = "base/models/#{c}.rb"
                is(File).file? file
                expect {File.read file} =~ /class #{c} < ActiveRecord/i
              end

              And 'yet behave well with namespaces' do
                file = "base/models/x/y/z.rb"
                is(File).file? file
                expect {File.read file} =~ /class Z < ActiveRecord/i
              end
            end
          end
          cleanup
        end
      end
    end
  end
end
