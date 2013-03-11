module Enginery
  module Test
    ORMs.each do |orm|
      Spec.new orm + 'Migrator' do
        
        Dir.chdir DST_ROOT do
          Testing do

            is(new_app "App o:#{orm}").ok?

            Dir.chdir 'App' do

              Context 'creating model' do
                is(new_model 'A column:name').ok?

                Context 'adding new column' do
                  is(new_migration 'addAboutColumn model:A column:about:text').ok?

                  Context 'running "up" auto-generated migration' do
                    is(migrate_up! 1).ok?

                    Context 'running "up" manually added migration' do
                      is(migrate_up! 2).ok?

                      Ensure 'all columns are in place' do
                        table = table('as')
                        check(table).has_column('name',  :string)
                        check(table).has_column('about', :text)

                        Context 'running "down" manual migration' do
                          Should 'drop "about" column' do
                            is(migrate_down! 2).ok?
                            check(table 'as').has_no_column 'about'
                          end
                        end

                        Context 'running "down" auto-migration' do
                          Should 'drop model table' do
                            is(migrate_down! 1).ok?
                            expect { table 'as' }.to_raise_error Mysql::Error
                          end
                        end

                      end
                    end
                  end
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
