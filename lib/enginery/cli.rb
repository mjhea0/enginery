module Enginery
  class CLI
    include Enginery::Helpers
    
    %w[controller route helper view spec model admin].each do |unit|
      define_method 'new_' + unit do |*args|
        run '"%s" g:%s %s' % [executable, unit, args.flatten*' ']
      end
    end

    def new_migration *args
      run '"%s" m %s' % [executable, args.flatten*' ']
    end

    def run_migration vector, force_run, file, setups
      run '"%s" m:%s:%s f:%s %s' % [executable, vector, force_run, file, setups]
    end

    def bundle task
      run 'bundle %s' % task, output_cmd: true
    end

    def executable
      $0
    end

    def run cmd, opts = {}
      opts[:output_cmd] && (o; o(cmd))
      PTY.spawn cmd do |r, w, pid|
        begin
          r.sync
          r.each_line do |line|
            o line.rstrip!
          end
        rescue Errno::EIO # simply ignoring this
        ensure
          ::Process.wait pid
        end
      end
      $? && $?.exitstatus == 0
    end

  end
end
