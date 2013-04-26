module Enginery
  module Test
    module SpecGenerator

      Spec.new self do

        Dir.chdir DST_ROOT do
          is(new_app 'App').ok?
          Dir.chdir 'App' do
            does(File.read 'Rakefile') =~ /Specular\.new/

            is(new_controller 'A').ok?

            Ensure 'it generated specs for A controller' do
              is(File).file? 'base/specs/a/index_spec.rb'
              does( new_test ' -D' ) =~ /test\:A/

              Ensure 'auto-generated spec runs well' do
                are( new_test 'A' ).ok?
              end
            end

            Should 'play well with namespaced controllers' do
              is(new_controller 'X::Y::Z').ok?
              is(new_route 'X::Y::Z  foo').ok?
              is(File).file? 'base/specs/x/y/z/foo_spec.rb'
            end

            Ensure 'all specs are detected and runs well' do
              are(all_tests).ok? do |output|
                check( output ) =~ /Specs:\s+4/
              end
            end

          end
        end
      end

    end
  end
end
