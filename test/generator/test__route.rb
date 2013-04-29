module Enginery
  module Test
    module RouteGenerator
      Spec.new self do

        Should 'fail cause not inside Espresso application' do
          does(new_route 'Foo bar').fail_with? /not.*Espresso.*application/im
        end

        Dir.chdir DST_ROOT do
          Testing do

            is(new_app 'App').ok?

            Dir.chdir 'App' do
              
              Should 'fail with "controller does not exists"' do
                does(new_route 'Foo bar').fail_with? =~ /controller does not exists/
              end

              is(new_controller 'Foo').ok?

              Should 'create a basic route' do
                is(new_route 'Foo bar').ok?

                file = 'base/controllers/foo/bar.rb'
                is(File).file? file
                expect(File.read file) =~ /def\s+bar\n/
              end
              
              Should 'create a route with setups' do
                is(new_route 'Foo setuped engine:Slim format:html').ok?

                file = 'base/controllers/foo/setuped.rb'
                is(File).file? file
                code = File.read file
                expect(code) =~ /format_for\s+:setuped\,\s+\Whtml/
                expect(code) =~ /before\s+:setuped\s+do[\n|\s]+engine\s+:Slim/
                expect(code) =~ /def\s+setuped/m
              end

              Should 'correctly convert route into file and method names' do
                {
                  'bar/baz' => 'bar__baz',
                  'bar-baz' => 'bar___baz',
                  'bar.baz' => 'bar____baz',
                }.each_pair do |route, meth|
                  Testing "#{route} to #{meth}" do
                    is(new_route "Foo #{route}").ok?

                    file = "base/controllers/foo/#{meth}.rb"
                    is(File).file? file
                    expect(File.read file) =~ /def\s+#{meth}/
                  end
                end
              end

              Should 'inherit engine defined at controller generation' do
                is(new_controller 'Pages e:Slim').ok?
                is(new_route 'Pages edit').ok?

                is(File).file? 'base/views/pages/edit.slim'

                And 'override it when explicitly given' do
                  is(new_route 'Pages create e:Haml').ok?

                  is(File).file? 'base/views/pages/create.haml'
                end
              end

            end
          end
          cleanup

          Should 'inherit engine defined at project generation' do
            is(new_app 'App e:Slim').ok?
            
            Dir.chdir 'App' do
              is(new_controller 'Foo').ok?
              is(new_route 'Foo  bar').ok?

              is(File).file? 'base/views/foo/bar.slim'
            end
          end
          cleanup

          Should 'create multiple routes' do
            is(new_app 'App').ok?
            
            Dir.chdir 'App' do
              is(new_controller 'Foo').ok?
              are(new_routes 'Foo a b c e:Slim').ok?

              %w[a b c].each do |r|
                Testing "#{r} route" do
                  file = "base/controllers/foo/#{r}.rb"
                  is(File).file? file
                  code = File.read file
                  expect {code} =~ /class Foo\n/i
                  is(File).file? "base/views/foo/#{r}.slim"
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
