module Enginery
  module Test
    module DeleteView
      Spec.new self do
        Dir.chdir DST_ROOT do

          is(new_app 'App').ok?

          Dir.chdir 'App' do

            Testing 'with default engine' do
              entries = [
                'base/views/foo/bar.erb',
              ]

              is(new_controller 'Foo').ok?
              is(new_route 'Foo bar').ok?
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_view 'Foo bar').ok?
              entries.each do |e|
                refute(File).exists? e
              end
            end

            Testing 'with custom engine' do
              entries = [
                'base/views/baz/bar.slim',
              ]

              is(new_controller 'Baz e:Slim').ok?
              is(new_route 'Baz bar').ok?
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_view 'Baz bar').ok?
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
