module Enginery
  module Test
    module DeleteController
      Spec.new self do

        Dir.chdir DST_ROOT do

          is(new_app 'App').ok?

          Dir.chdir 'App' do

            entries = [
              'base/controllers/foo/',
              'base/controllers/foo' + Enginery::CONTROLLER_SUFFIX,
              'base/controllers/foo/bar' + Enginery::ROUTE_SUFFIX,
              'base/views/foo/bar.erb',
              'base/specs/foo/bar' + Enginery::SPEC_SUFFIX
            ]

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
        end

      end
    end
  end
end
