module Enginery
  module Test
    module ControllerGenerator
      Spec.new self do

        Should 'fail cause not inside Espresso application' do
          does(new_controller 'Foo').fail_with? /not a generated Espresso application/
        end

        Dir.chdir DST_ROOT do
          Testing do

            is(new_app 'App').ok?

            Dir.chdir 'App' do
              Context 'creating controllers' do

                Should 'create an unmapped controller' do
                  is(new_controller 'Foo').ok?
                  
                  dir = 'base/controllers/foo'
                  is(File).directory? dir
                  file = dir + '_controller.rb'
                  is(File).file? file
                  expect(File.read file) =~ /class\s+Foo\s+<\s+E\n/
                end

                Should 'create a mapped controller' do
                  is(new_controller 'Bar r:bar').ok?
                  
                  dir = 'base/controllers/bar'
                  is(File).directory? dir
                  file = dir + '_controller.rb'
                  is(File).file? file
                  expect(File.read file) =~ /map\s+\Wbar/m
                end

                Should 'create a controller with setups' do
                  is(new_controller 'Baz engine:Slim format:html').ok?
                  
                  dir = 'base/controllers/baz'
                  is(File).directory? dir
                  file = dir + '_controller.rb'
                  is(File).file? file
                  code = File.read(file)
                  expect(code) =~ /format\s+\Whtml/m
                  expect(code) =~ /engine\s+:Slim/m
                end

                Should 'fail with "constant already in use"' do
                  does(new_controller 'Baz').fail_with? /already in use/i
                end

                Should 'correctly handle namespaces' do
                  is(new_controller 'A::B::C').ok?

                  dir = 'base/controllers/a/b/c'
                  is(File).directory? dir
                  file = dir + '_controller.rb'
                  is(File).file? file
                  code = File.read(file)
                  expect(code) =~ /module A/
                  expect(code) =~ /module B/
                  expect(code) =~ /class C < E/
                end

              end
            end
          end
          cleanup

          Should 'inherit engine defined at project generation' do
            is(new_app 'App e:Slim').ok?
            
            Dir.chdir 'App' do
              is(new_controller 'Foo').ok?

              is(File).file? 'base/views/foo/index.slim'

              Should 'include modules provided via include: option' do
                is(new_controller 'Bar i:Rack::Utils').ok?

                file = 'base/controllers/bar_controller.rb'
                is(File).file? file
                does(File.read file) =~ /include Rack::Utils/
              end
            end
          end
          cleanup

          Should 'create multiple controllers at once' do
            is(new_app 'App').ok?
            
            Dir.chdir 'App' do
              are(new_controllers 'A B C  X::Y::Z  e:Slim').ok?

              %w[a b c].each do |c|
                dir = "base/controllers/#{c}"
                is(File).directory? dir
                file = dir + "_controller.rb"
                is(File).file? file
                expect {File.read file} =~ /class #{c} < E/i
                is(File).file? "base/views/#{c}/index.slim"
              end

              And 'yet behave well with namespaces' do
                dir = "base/controllers/x/y/z"
                is(File).directory? dir
                file = dir + "_controller.rb"
                is(File).file? file
                is(File).file? "base/views/x/y/z/index.slim"
              end

            end
          end
          cleanup

        end

      end
    end
  end
end
