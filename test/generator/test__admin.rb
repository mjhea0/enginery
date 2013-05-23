module Enginery
  module Test
    module AdminGenerator

      Spec.new self do
        base_path = 'base/controllers/rear-controllers/'

        Dir.chdir DST_ROOT do
          is(new_app 'App').ok?

          Dir.chdir 'App' do
            is(new_model 'A').ok?
            is(File).file? base_path + 'a' + ADMIN_SUFFIX

            Should 'play well with namespaced models' do
              is(new_model 'X::Y::Z').ok?
              is(File).file? base_path + 'x/y/z' + ADMIN_SUFFIX
            end

            Testing 'manual generation' do
              is(new_model 'B').ok?

              file = base_path + 'b' + ADMIN_SUFFIX
              is(File).file? file
              # accidentally removing controller file...
              FileUtils.rm file
              refute(File).file? file

              is(new_admin_controller 'B').ok?
              is(File).file? file
            end

          end
        end
      end

    end
  end
end
