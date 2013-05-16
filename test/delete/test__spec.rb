module Enginery
  module Test
    module DeleteSpec
      Spec.new self do

        Dir.chdir DST_ROOT do

          is(new_app 'App').ok?

          Dir.chdir 'App' do

            entries = [
              'base/specs/foo/bar' + Enginery::SPEC_SUFFIX
            ]
            Should 'be deleted alongside controller' do
              is(new_controller 'Foo').ok?
              is(new_route 'Foo bar').ok?
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_controller 'Foo').ok?
              entries.each do |e|
                refute(File).exists? e
              end
            end
            Should 'be deleted alongside route' do
              is(new_controller 'Foo').ok?
              is(new_route 'Foo bar').ok?
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_route 'Foo bar').ok?
              entries.each do |e|
                refute(File).exists? e
              end
            end
            Should 'be deleted manually' do
              delete_controller 'Foo'
              is(new_controller 'Foo').ok?
              is(new_route 'Foo bar').ok?
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_spec 'Foo bar').ok?
              entries.each do |e|
                refute(File).exists? e
              end
            end
          
          end
        end

      end
    end
  end
end
