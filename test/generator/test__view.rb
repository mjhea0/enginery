module Enginery
  module Test
    module ViewGenerator
      Spec.new self do

        Should 'fail cause not inside Espresso application' do
          does(new_view 'Foo bar').fail_with? =~ /not a generated Espresso application/
        end

        Dir.chdir DST_ROOT do
          Testing do

            is(new_app 'App').ok?

            Dir.chdir 'App' do
              Should 'fail with "controller does not exists"' do
                does(new_view 'Foo bar').fail_with? =~ /controller does not exists/
              end

              is(new_controller 'Foo').ok?

              Should 'fail with "action does not exists"' do
                does(new_view 'Foo bar').fail_with? =~ /action does not exists/
              end

              Ensure 'template automatically created at route generation' do
                is(new_route 'Foo bar').ok?
                is(File).file? 'base/views/foo/bar.erb'
              end

              Should 'correctly convert route to template name' do
                is(new_route 'Foo bar/baz').ok?
                is(File).file? 'base/views/foo/bar__baz.erb'
              end

              Should "use controller name for path to templates" do
                is(new_controller 'Bar r:bars_base_addr').ok?
                is(new_route 'Bar some_route').ok?
                is(File).file? 'base/views/bar/some_route.erb'
              end

              Should 'correctly handle namespaces' do
                is(new_controller 'A::B::C').ok?
                dir = 'base/views/a/b/c'
                is(File).directory? dir
                file = dir + '/index.erb'
                is(File).file? file
              end
            end
          end
          cleanup

          Ensure 'extension correctly set' do
            is(new_app 'App e:Sass').ok?

            Dir.chdir 'App' do
              When 'engine are set at project generation' do
                is(new_controller 'ESP').ok?

                is(new_route 'ESP foo').ok?
                is(File).file? 'base/views/esp/foo.sass'
              end

              And 'when engine are set at controller generation' do
                is(new_controller 'ESC e:Slim').ok?

                is(new_route 'ESC foo').ok?
                is(File).file? 'base/views/esc/foo.slim'

                And 'when engine are set at route generation' do

                  is(new_route 'ESC bar e:Haml').ok?
                  is(File).file? 'base/views/esc/bar.haml'
                end
              end

            end
          end
          cleanup
        end

      end
    end
  end
end
