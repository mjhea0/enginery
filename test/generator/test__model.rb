module Enginery
  module Test
    module ModelGenerator
      Spec.new self do

        Dir.chdir DST_ROOT do
          Should 'generate a plain class cause no setups given' do
            is(new_app 'App').ok?

            Dir.chdir 'App' do
              is(new_model 'Foo').ok?

              file = 'base/models/foo.rb'
              is(File).file? file
              expect(File.read file) =~ /class\s+Foo\n/

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

              Should 'generate multiple models' do
                
                are(new_models 'Bar Baz X::Y::Z').ok?

                %w[Bar Baz].each do |c|
                  file = "base/models/#{c.downcase}.rb"
                  is(File).file? file
                  expect {File.read file} =~ /class #{c}/i
                end

                And 'yet behave well with namespaces' do
                  file = "base/models/x/y/z.rb"
                  is(File).file? file
                  expect {File.read file} =~ /class Z/i
                end
             
              end

              Should 'include modules provided via include: option' do
                is(new_model 'BarBaz i:Rack::Utils').ok?

                file = 'base/models/bar_baz.rb'
                is(File).file? file
                does(File.read file) =~ /include Rack::Utils/
              end

            end
          end
          cleanup
        end
      end

      Spec.new self do
        Dir.chdir DST_ROOT do
        
          Should 'correctly handle ActiveRecord associations' do
            is(new_app 'App orm:ar').ok?

            Dir.chdir 'App' do
              model_file = "base/models/foo.rb"

              is(new_model 'Foo belongs_to:bar').ok?
              does(model_file).contain? /belongs_to\W+bar/
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_one:bar').ok?
              does(model_file).contain? /has_one\W+bar/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_one:bar:through:baz').ok?
              does(model_file).contain? /has_one\W+bar\W+through\W+baz/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_many:bars').ok?
              does(model_file).contain? /has_many\W+bars/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_many:bars:through:baz').ok?
              does(model_file).contain? /has_many\W+bars\W+through\W+baz/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_and_belongs_to_many:bars').ok?
              does(model_file).contain? /has_and_belongs_to_many\W+bars/i
              is(delete_model 'Foo').ok?

              Should 'handle multiple associations' do
                is(new_model 'Foo belongs_to:bar belongs_to:baz has_many:related_bars').ok?
                does(model_file).contain? /belongs_to\W+bar/
                does(model_file).contain? /belongs_to\W+baz/
                does(model_file).contain? /has_many\W+related_bars/
                is(delete_model 'Foo').ok?

                is(new_model 'Foo has_and_belongs_to_many:bars has_many:barz:through:baz').ok?
                does(model_file).contain? /has_and_belongs_to_many\W+bars/i
                does(model_file).contain? /has_many\W+barz\W+through\W+baz/i
                is(delete_model 'Foo').ok?
              end
            end
          end
          cleanup

          Should 'correctly handle DataMapper associations' do
            is(new_app 'App orm:dm').ok?

            Dir.chdir 'App' do
              model_file = "base/models/foo.rb"

              is(new_model 'Foo belongs_to:bar').ok?
              does(model_file).contain? /belongs_to\W+bar/
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_one:bar').ok?
              does(model_file).contain? /has\s+1\W+bar/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_one:bar:through:baz').ok?
              does(model_file).contain? /has\s+1\W+bar\W+through\W+baz/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_many:bars').ok?
              does(model_file).contain? /has\s+n\W+bars/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_many:bars:through:baz').ok?
              does(model_file).contain? /has\s+n\W+bars\W+through\W+baz/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_and_belongs_to_many:bars').ok?
              does(model_file).contain? /has\s+n\W+bars/i
              is(delete_model 'Foo').ok?

              Should 'handle multiple associations' do
                is(new_model 'Foo belongs_to:bar has_many:related_bars').ok?
                does(model_file).contain? /belongs_to\W+bar/
                does(model_file).contain? /has\s+n\W+related_bars/
                is(delete_model 'Foo').ok?

                is(new_model 'Foo has_many:related_bars has_many:bars:through:related_bars').ok?
                does(model_file).contain? /has\s+n\W+related_bars/
                does(model_file).contain? /has\s+n\W+bars\W+through\W+related_bars/
                is(delete_model 'Foo').ok?
              end
            end
          end
          cleanup

          Should 'correctly handle Sequel associations' do
            is(new_app 'App orm:sq').ok?

            Dir.chdir 'App' do
              model_file = "base/models/foo.rb"

              is(new_model 'Foo belongs_to:bar').ok?
              does(model_file).contain? /many_to_one\W+bar/
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_one:bar').ok?
              does(model_file).contain? /one_to_one\W+bar/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_many:bars').ok?
              does(model_file).contain? /one_to_many\W+bars/i
              is(delete_model 'Foo').ok?

              is(new_model 'Foo has_and_belongs_to_many:bars').ok?
              does(model_file).contain? /many_to_many\W+bars/i
              is(delete_model 'Foo').ok?

              Should 'handle multiple associations' do
                is(new_model 'Foo belongs_to:bar has_many:related_bars').ok?
                does(model_file).contain? /many_to_one\W+bar/
                does(model_file).contain? /one_to_many\W+related_bars/
                is(delete_model 'Foo').ok?
              end
            end
          end
          cleanup
        end

      end
    end
  end
end
