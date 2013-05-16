module Enginery
  module Test
    module HelperGenerator

      Spec.new self do

        Dir.chdir DST_ROOT do
          is(new_app 'App').ok?
          Dir.chdir 'App' do
            Should 'be auto-generated alongside controller' do
              is(new_controller 'A').ok?
              controller_file = 'base/controllers/a_controller.rb'
              is(File).file? controller_file

              Ensure 'it generated a helper file for A controller' do
                helper_file = 'base/helpers/a.rb'
                is(File).file? helper_file
                
                Ensure 'generated helper include application helpers' do
                  does(File.read(helper_file)) =~ /include\s+Helpers/
                end

                Ensure 'controller include generated helper' do
                  does(File.read(controller_file)) =~ /include\s+AHelpers/
                end
              end

              Should 'play well with namespaced controllers' do
                is(new_controller 'X::Y::Z').ok?
                is(File).file? 'base/helpers/x/y/z.rb'
              end
            end

            Testing 'manual generation' do
              is(new_controller 'B').ok?

              helper_file = 'base/helpers/b.rb'
              is(File).file? helper_file
              FileUtils.rm helper_file
              refute(File).file? helper_file

              is(new_helper 'B').ok?
              is(File).file? helper_file

              Ensure 'generated helper include application helpers' do
                does(File.read(helper_file)) =~ /include\s+Helpers/
              end
            end

          end
        end
      end

    end
  end
end
