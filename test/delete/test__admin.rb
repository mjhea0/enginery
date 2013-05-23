module Enginery
  module Test
    module DeleteAdmin
      Spec.new self do

        Dir.chdir DST_ROOT do

          is(new_app 'App').ok?

          Dir.chdir 'App' do
            entries = [
              'base/controllers/rear-controllers/foo' + ADMIN_SUFFIX
            ]

            Should 'be deleted alongside model' do
              is(new_model 'Foo').ok?
              
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_model 'Foo').ok?
              entries.each do |e|
                refute(File).exists? e
              end
            end

            Should 'be deleted manually' do

              is(new_model 'Foo').ok?
              
              entries.each do |e|
                does(File).exists? e
              end

              is(delete_admin_controller 'Foo').ok?
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
