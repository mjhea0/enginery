module Enginery
  module Test
    module DeleteHelper
      Spec.new self do

        Dir.chdir DST_ROOT do

          is(new_app 'App').ok?

          Dir.chdir 'App' do
            entries = [
              'base/helpers/foo' + Enginery::HELPER_SUFFIX
            ]

            Should 'be deleted alongside controller' do
              is(new_controller 'Foo').ok?
              
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_controller 'Foo').ok?
              entries.each do |e|
                refute(File).exists? e
              end
            end

            Should 'be deleted manually' do

              is(new_controller 'Foo').ok?
              
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_helper 'Foo').ok?
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
