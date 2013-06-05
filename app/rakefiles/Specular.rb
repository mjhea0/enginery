
Dir[Cfg.specs_path('**/*_spec.rb')].each {|f| require f}

specular_session = Specular.new do
  boot do
    include Sonar
  end
  before do
    app App
    map App.base_url
  end
end

specular_tasks   = []
App.mounted_controllers.reject do |c|
  next if c.name == 'RearHomeController' || c.name =~ /::RearController\Z/
  task_name = 'test:%s' % c.name
  desc 'Run tests for "%s" controller' % c
  task task_name do
    puts specular_session.run /\A#{c}\W/
    specular_session.exit_code == 0 || fail
  end
  c.public_actions.each do |a|
    task 'test:%s#%s' % [c.name, a] do
      puts specular_session.run /\A#{c}##{a}\Z/
      specular_session.exit_code == 0 || fail
    end
  end
  specular_tasks << task_name
end

task 'test:each' => specular_tasks

desc 'Run all tests'
task :test do
  specular_session.run
  puts specular_session.failures if specular_session.failed?
  puts specular_session.summary
  specular_session.exit_code == 0 || fail
end
task default: :test
