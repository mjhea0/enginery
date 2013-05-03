module Enginery
  module Test
    module DeleteModel
      Spec.new self do

        Dir.chdir DST_ROOT do

          is(new_app 'App o:ar').ok?

          Dir.chdir 'App' do

            entries = [
              'base/models/foo' + Enginery::MODEL_SUFFIX
            ]

            is(new_model 'Foo').ok?
            migrations = Dir['base/migrations/foo/*' + Enginery::MIGRATION_SUFFIX]
            check(migrations).any?

            entries.each do |e|
              does(File).exists? e
            end

            is(delete_model 'Foo').ok?
            (entries + migrations).each do |e|
              refute(File).exists? e
            end
          
          end
        end

      end
    end
  end
end
