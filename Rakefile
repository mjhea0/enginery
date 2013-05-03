require 'rake'

require './test/setup'
Dir['./test/**/test__*.rb'].each { |f| require f }

def run unit = nil
  session = Specular.new
  session.boot do
    extend  Enginery::Test::SpecHelper
    include Enginery::Test::SpecHelper
    cleanup
  end
  session.halt do
    cleanup
  end
  puts "\n***\nTesting %s ..." % (unit ? unit : :everything)
  session.run %r[#{unit}]
  puts session.failures if session.failed?
  puts session.summary
  session.exit_code == 0
end

%w[Project Controller Route View Model Spec].each do |unit|
  desc('Run Tests for %s Generator' % unit)
  task('tg:' + unit.downcase[0]) { run(unit + 'Generator') || fail }
end
desc 'Run all Generator tests'
task(:tg) { run(:Generator) || fail }

%w[ActiveRecord DataMapper Sequel].each do |orm|
  desc('Run Tests for %s Migrator' % orm)
  task('tm:' + orm.downcase[0]) { run(orm + 'Migrator') || fail }
end
desc 'Run all Migrator tests'
task(:tm) { run(:Migrator) || fail }

%w[Controller Route View Spec Model Migration].each do |unit|
  desc('Run %s Deletion Tests' % unit)
  task('td:' + (unit =~ /m/i ?  unit.downcase[0..1] : unit.downcase[0])) { run('Delete' + unit) || fail }
end
desc 'Run all Deletion tests'
task(:td) { run(:Delete) || fail }

desc 'Run all tests'
task(:t) { run || fail }
desc 'Run all tests, alias for "t"'
task test: :t
task default: :t
