module Enginery
  module Test
    module ProjectGenerator

      Spec.new self do

        Dir.chdir DST_ROOT do

          Should 'create a basic project, without any setups' do
            is(new_app 'App').ok?
            is(File).directory? 'App'

            Should 'fail cause folder already contain an app' do
              does(new_app 'App').fail_with? /should be a empty folder/
            end
          end
          cleanup

          [
            ['ActiveRecord', 'activerecord'],
            ['DataMapper', 'data_mapper'],
            ['Sequel', 'sequel']
          ].each do |(o,g)|
            Testing o do
              cleanup

              is(new_app "App orm:#{o}").ok?

              Dir.chdir 'App' do
                Ensure 'config.yml updated' do
                  expect {
                    File.read 'config/config.yml'
                  } =~ /orm\W+#{o}/i
                end
                
                Ensure 'Gemfile updated' do
                  expect {
                    File.read 'Gemfile'
                  } =~ /gem\W+#{g}/i
                end

                Ensure 'database.rb updated' do
                  expect {
                    File.read 'base/database.rb'
                  } =~ /#{o}/
                end
              end
            end
          end
          cleanup

          %w[Haml Slim].each do |engine|
            Testing engine do
              cleanup
              is(new_app "App engine:#{engine} format:#{engine}").ok?

              Dir.chdir 'App' do
                Ensure 'config.yml updated' do
                  cfg = nil
                  expect {
                    cfg = File.read 'config/config.yml'
                  } =~ /engine\W+#{engine}/i
                  expect { cfg } =~ /format\W+#{engine}/
                end
                
                Ensure 'Gemfile updated' do
                  expect {
                    File.read 'Gemfile'
                  } =~ /gem\W+#{engine}/im
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
