module Enginery
  module Test
    
    ORMs.each do |orm|
      Spec.new orm + 'Migrator' do
        
        Dir.chdir DST_ROOT do
          Testing do

            is(new_app "App o:#{orm}").ok?

            Dir.chdir 'App' do

              Context 'creating model. this will also generate a migration' do
                is(new_model 'A add_column:name').ok?
                is(migrate_up! 1).ok?

                Should 'skip repetitive "up" migrations' do
                  is(migrate_up! 1).skipped?
                end

                Context 'performing migration down' do
                  is(migrate_down! 1).ok?

                  Should 'skip repetitive "down" migrations' do
                    is(migrate_down! 1).skipped?
                  end

                  Ensure '"up" migration runs ok after "down" migration performed' do
                    is(migrate_up! 1).ok?
                  end

                  Context 'adding/updating columns' do
                    is(new_migration("addEmail model:A add_column:email:string")).ok?
                    
                    Ensure '"up" is adding "email" column and "down" is dropping it' do
                      check(table('as')).has_no_column('email')

                      is(migrate_up! 2).ok?
                      check(table('as')).has_column('email',  :string)
                      
                      is(migrate_down! 2).ok?
                      check(table('as')).has_no_column('email')

                      Ensure 'up migration runs ok after down migration performed' do
                        is(migrate_up! 2).ok?
                        check(table('as')).has_column('email',  :string)

                        Ensure '"up" is changing "email" type to "text"' do
                          is(new_migration("chEmail model:A update_column:email:text")).ok?

                          is(migrate_up! 3).ok?
                          check(table('as')).has_column('email',  :text)

                          And '"down" is reverting it to "string"' do
                            is(migrate_down! 3).ok?
                            check(table('as')).has_column('email',  :string)
                          end
                        end
                        
                      end
                    end
                  end
                end

                if orm == 'DataMapper'
                  # running this test only on DataMapper
                  model_file = 'base/models/a.rb'

                  Should 'update model file by adding/updating properties' do

                    is(new_migration("addFoo model:A column:foo")).ok?
                    
                    refute(File.read(model_file)) =~ /property\W+foo/
                    migrate_up!(4)
                    does(File.read(model_file)) =~ /property\W+foo/

                    Ensure 'foo type updated' do
                      does(File.read(model_file)) =~ /property\W+foo\W+String/
                      is(new_migration("updateBAR model:A update_column:foo:text")).ok?
                      migrate_up!(5)
                      refute(File.read(model_file)) =~ /property\W+foo\W+String/
                      does(File.read(model_file)) =~ /property\W+foo\W+Text/
                    end
                    
                    Ensure 'foo renamed to bar' do
                      is(new_migration("fooTObar model:A rename_column:foo:bar")).ok?
                      migrate_up!(6)
                      refute(File.read(model_file)) =~ /property\W+foo/
                      does(File.read(model_file))  =~ /property\W+bar/
                    end
                  
                  end

                  Should 'update model file by removing properties' do
                    is(new_migration("addRemoveMe model:A column:removeme")).ok?
                    is(migrate_up! 7).ok?
                    does(File.read(model_file)) =~ /property\W+removeme/
                    delete_migration(7)
                    refute(File.read(model_file)) =~ /property\W+removeme/
                  end
                  
                else
                  # `rename_column` is broken on DataMapper 1.2.0
                  # so skipping renameColumnsTest for DataMapper until fix released.

                  Context 'renaming columns' do

                    is(new_migration("reName model:A rename_column:name:first_name")).ok?

                    table = table('as')
                    check(table).has_column('name')
                    check(table).has_no_column('first_name')

                    Ensure '"up" section is renaming "name" to "first_name"' do
                      is(migrate_up! 4).ok?
                      table = table('as')
                      check(table).has_column('first_name')
                      check(table).has_no_column('name')
                      Ensure '"down" section renaming "first_name" to "name"' do
                        is(migrate_down! 4).ok?
                        table = table('as')
                        check(table).has_column('name')
                        check(table).has_no_column('first_name')
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
