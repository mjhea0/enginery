module Enginery
  module Helpers

    # TODO: refactor this huge method
    def parse_input *input
      input.flatten!
      args, setups, string_setups = [], {}, []
      input.each do |a|
        case

        # generator
        when a =~ /\Ao(rm)?:/
          orm = extract_setup(a)
          if valid_orm = valid_orm?(orm)
            setups[:orm] = valid_orm
            string_setups << a
          else
            fail_verbosely 'Invalid ORM provided - "%s"' % orm, \
              'Supported ORMs: ActiveRecord, DataMapper, Sequel'
          end
        when a =~ /\Ae(ngine)?:/
          smth = extract_setup(a)
          if engine = valid_engine?(smth)
            setups[:engine] = engine
            string_setups << a
          else
            fail_verbosely 'Invalid engine provided - %s' % smth, \
              'Supported engines(Case Sensitive): %s' % EConstants::VIEW__ENGINE_BY_SYM.keys.join(', ')
          end
        when a =~ /\Af(ormat|ile)?:/
          if format = extract_setup(a)
            # format if used by generator, file is used by migrator
            setups[:format] = setups[:file] = format
            string_setups << a
          end
        when a =~ /\Ar(oute)?:/
          if route = extract_setup(a)
            setups[:route] = route
            string_setups << a
          end
        when a =~ /\Adb/
          [:type, :host, :port, :name, :user, :pass].each do |s|
            if (a =~ /\Adb(_)?#{s}:/) && (v = extract_setup(a))
              (setups[:db] ||= {}).update s => (s == :type ? valid_db_type?(v) : v)
              string_setups << a
            end
          end
        when a =~ /\As(erver)?:/
          smth = extract_setup(a)
          if server = valid_server?(smth)
            setups[:server] = server.to_sym
            string_setups << a
          else
            fail_verbosely 'Unknown server provided - %s' % smth, \
              'It wont be added to Gemfile nor to config.yml', \
              'Known servers(Case Sensitive): %s' % KNOWN_WEB_SERVERS.join(', ')
          end
        when a =~ /\Ap(ort)?:/
          smth = extract_setup(a)
          if (port = smth.to_i) > 0
            setups[:port] = port
            string_setups << a
          else
            fail_verbosely 'Invalid port provided - %s' % smth, 'Port should be a number'
          end
        when a =~ /\Ah(ost(s)?)?:/
          if hosts = extract_setup(a)
            setups[:hosts] = hosts.split(',')
            string_setups << a
          end
        when a =~ /\Ai(nclude)?:/
          mdl = validate_constant_name extract_setup(a)
          (setups[:include] ||= []).push mdl
          string_setups << a

        # migrator
        when a =~ /\Acreate_table_for:/
          if table = extract_setup(a)
            setups[:create_table] = table
            string_setups << a
          end
        when a =~ /\Am(odel)?:/
          if table = extract_setup(a)
            setups[:update_table] = table
            string_setups << a
          end
        when a =~ /\Aa?(dd_)?c(olumn)?:/
          if column = extract_setup(a)
            (setups[:create_columns] ||= []).push column.split(':')
            string_setups << a
          end
        when a =~ /\Au(pdate_)?c?(olumn)?:/
          if column = extract_setup(a)
            (setups[:update_columns] ||= []).push column.split(':')
            string_setups << a
          end
        when a =~ /\Ar(ename_)?c?(olumn)?:/
          if column = extract_setup(a)
            (setups[:rename_columns] ||= []).push column.split(':')
            string_setups << a
          end
        else
          args.push(a) unless ORM_ASSOCIATIONS.find {|an| a =~ /#{an}/}
        end
      end
      ORM_ASSOCIATIONS.each do |a|
        input.select {|x| x =~ /\A#{a}:/}.each do |s|
          next unless v = extract_setup(s)
          (setups[a] ||= []).push v
          string_setups << s
        end
      end
      [args.freeze, setups.freeze, string_setups.join(' ').freeze]
    end
    module_function :parse_input

    def extract_setup input
      input.scan(/:(.+)/).flatten.last
    end
    module_function :extract_setup
    
  end
end
