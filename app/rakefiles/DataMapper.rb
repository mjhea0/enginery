
namespace :dm do
  %w[auto_migrate auto_upgrade].each do |t|
    alert = t == 'auto_migrate' ? 'ACHTUNG! This is a DESTRUCTIVE action!' : nil

    ObjectSpace.each_object(Class).select do |c|
      c.ancestors.include?(DataMapper::Resource)
    end.each do |m|
      run = lambda do
        puts '', '  Running %s.%s!' % [m.name, t], ''
        m.send(t + '!')
      end
      
      desc 'Run %s.%s! %s' % [m.name, t, alert]
      task [t, m.name]*':' do
        if alert
          puts '', alert
          puts '  The table for %s model will be destroyed and recreated from ground up.' % m.name
          puts '  Any data will be lost, so please consider to take some backups before continuing.', ''
          puts '  Type Y and press enter to continue'
          puts '  Press enter to cancel'
          answer = STDIN.gets.strip
          (puts 'exiting...'; exit(0)) unless answer == 'Y'
        end
        run.call
      end
      task([t, m.name ,'y']*':') { run.call }
    end

    run = lambda do
      puts '', '  Running DataMapper.%s!' % t, ''
      DataMapper.send(t + '!')
    end
    desc 'Run DataMapper.%s! %s' % [t, alert]
    task t do
      if alert
        puts '', alert
        puts '  ALL tables will be destroyed and recreated from ground up.'
        puts '  Any data will be lost, so please consider to take some backups before continuing.', ''
        puts '  Type Y and press enter to continue'
        puts '  Press enter to cancel'
        answer = STDIN.gets.strip
        (puts 'exiting...'; exit(0)) unless answer == 'Y'
      end
      run.call
    end
    task(t + ':y'){ run.call }
  end
end
