
Dir[Cfg.specs_path('**/*_spec.rb')].each {|f| require f}

SpecularSession = Specular.new do
  boot do
    include Sonar
  end
  before do
    app App
    map App.base_url
  end
end

namespace :test do
  App.mounted_controllers.each do |c|
    [nil].concat(c.public_actions).each do |action|
      task_name = [c.name, action].compact*'#'
      desc 'Run tests for %s' % task_name
      task task_name do
        puts "\n--- Testing %s ---" % task_name
        puts SpecularSession.run %r[\A#{task_name}]
        SpecularSession.exit_code == 0 || fail
      end
    end
  end
end

desc 'Run all tests'
task :test do
  puts "\n--- Testing everything ---"
  puts SpecularSession.run
  SpecularSession.exit_code == 0 || fail
end
task default: :test
