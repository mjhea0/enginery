
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
  next if c.ancestors.map(&:to_s).include? 'Rear'
  task_name = 'test:' + c.name
  desc 'Run tests for "%s" controller' % c
  task task_name do
    puts "", "*** %s ***" % task_name
    puts specular_session.run /\A#{c}\W/
    specular_session.exit_code == 0 || fail
  end
  specular_tasks << task_name
end

desc 'Run all tests'
task test: specular_tasks
task default: :test
