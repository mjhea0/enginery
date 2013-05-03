module Enginery
  module Test
    module DeleteMigration
      Spec.new self do

        Dir.chdir DST_ROOT do

          is(new_app 'App o:dm').ok?

          Dir.chdir 'App' do

            is(new_model 'Foo').ok?
            migrations = Dir['base/migrations/foo/*' + Enginery::MIGRATION_SUFFIX]
            check(migrations).any?

            is(delete_migration '1').ok?
            migrations.each do |e|
              refute(File).exists? e
            end
          
          end
        end

      end
    end
  end
end
