module Enginery
  module Test
    ORMs.each do |orm|
      Spec.new orm + 'Migrator' do
        
        Dir.chdir DST_ROOT do
          Testing do

            is(new_app "App o:#{orm}").ok?

            Dir.chdir 'App' do

              Ensure 'valid migration generated alongside with generated model' do
                is(new_model 'A column:name column:about:text').ok?
                is(migrate_up! 1).ok?

                Ensure 'all columns are in place' do
                  table = table('as')
                  check(table).has_column('name',  :string)
                  check(table).has_column('about', :text)
                end
                
                Ensure 'migrator plays well with namespaces' do
                  is(new_model 'X::Y::Z column:name').ok?

                  is(migrate_up! 2).ok?

                  table = table(orm == 'DataMapper' ? 'x_y_zs' : 'zs')
                  check(table).has_column('name',  :string)
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
