
namespace :dm do
  %w[auto_migrate auto_upgrade].each do |t|
    alert = 'ACHTUNG! This is a DESTRUCTIVE action!' if t == 'auto_migrate'
    ObjectSpace.each_object(Class).select do |c|
      c.ancestors.include?(DataMapper::Resource)
    end.each do |m|
      desc 'Run %s.%s! %s' % [m, t, alert]
      task [t,m]*':' do
        puts "\n  Running %s.%s!\n\n" % [m,t]
        m.send(t + '!')
      end
    end

    desc 'Run DataMapper.%s! %s' % [t, alert]
    task t do
      puts "\n  Running DataMapper.%s!\n\n" % t
      DataMapper.send(t + '!')
    end
  end
end
