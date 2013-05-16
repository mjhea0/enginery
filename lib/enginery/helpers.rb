module Enginery
  class Failure
    attr_reader :failures
    def initialize *failures
      @failures = failures
    end
  end

  module Helpers
    include EUtils

    def src_path *args
      @src_path_map ||= begin
        paths = { :root => File.expand_path('../../../app', __FILE__) + '/' }
        [
          :base,
          :gemfiles,
          :rakefiles,
          :specfiles,
          :database,
          :migrations,
        ].each {|d| paths[d] = File.join(paths[:root], d.to_s, '')}
        paths.values.map(&:freeze)
        [paths, Struct.new(*paths.keys).new(*paths.values)]
      end
      paths, struct = @src_path_map
      return struct if  args.empty?
      
      paths[args.first] || fail('%s is not a recognized source path.
        Use one of %s' % [args.first.inspect, paths.map(&:inspect)*', '])
      File.join(paths[args.shift], *args.map(&:to_s)).gsub(/\/+/, '/').freeze
    end

    def dst_path *args
      @dst_path_map ||= begin
        paths = { :root => @dst_root.to_s.gsub(/\/+/, '/') }
        [
          :base,
          :config,
        ].each {|p| paths[p] = File.join(paths[:root], p.to_s, '')}
        [
          :controllers,
          :models,
          :views,
          :specs,
          :migrations,
          :helpers
        ].each {|d| paths[d] = File.join(paths[:base], d.to_s, '')}

        paths[:config_yml]   = File.join(paths[:config], 'config.yml')
        paths[:database_yml] = File.join(paths[:config], 'database.yml')
        
        [
          :Rakefile,
          :Gemfile,
        ].each {|f| paths[f] = File.join(paths[:root], f.to_s)}
        [
          :boot_rb,
          :database_rb,
        ].each {|f| paths[f] = File.join(paths[:base], f.to_s.sub('_rb', '.rb'))}
        paths.values.map(&:freeze)
        [paths, Struct.new(*paths.keys).new(*paths.values)]
      end
      paths, struct = @dst_path_map
      return struct if  args.empty?
      
      paths[args.first] || fail('%s is not a recognized destination path.
        Use one of %s' % [args.first.inspect, paths.map(&:inspect)*', '])
      File.join(paths[args.shift], *args.map(&:to_s)).gsub(/\/+/, '/').freeze
    end

    # TODO: refactor this huge method
    def parse_input *input
      args, setups, string_setups = [], {}, []
      input.flatten.each do |a|
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
        when a =~ /\Au(pdate_)?c(olumn)?:/
          if column = extract_setup(a)
            (setups[:update_columns] ||= []).push column.split(':')
            string_setups << a
          end
        when a =~ /\Ar(ename_)?c(olumn)?:/
          if column = extract_setup(a)
            (setups[:rename_columns] ||= []).push column.split(':')
            string_setups << a
          end
        else
          args << a
        end
      end
      [args.freeze, setups.freeze, string_setups.join(' ').freeze]
    end
    module_function :parse_input

    def in_app_folder?
      File.directory?(dst_path.controllers)
    end

    def fail_unless_in_app_folder!
      in_app_folder? || fail("Seems current folder does not contain a Espresso application")
    end

    def fail *failures
      throw :enginery_failures, Failure.new(*failures)
    end
    module_function :fail

    def fail_verbosely *failures
      o *failures
      fail *failures
    end
    module_function :fail_verbosely

    def load_boot_rb
      pv, $VERBOSE = $VERBOSE, nil
      orig = Array.new($:)
      # loading app
      load dst_path.boot_rb
      # for some reason, Bundler get rid of existing loadpath entries.
      # usually this will break autoloading, so storing orig paths and inserting them back
      orig.each {|p| $:.include?(p) || $: << p}
    ensure
      $VERBOSE = pv
    end

    def boot_app
      load_boot_rb
      App.boot!
    end

    def app_controllers
      App.mounted_controllers.select {|c| controller_exists?(c.name)}
    end

    def routes_by_controller controller
      Dir[dst_path(:controllers, class_to_route(controller), '*' + ROUTE_SUFFIX)].map do |f|
        File.basename(f, File.extname(f))
      end
    end

    def controller_exists? name
      path = dst_path(:controllers, class_to_route(name))
      File.file?(path + CONTROLLER_SUFFIX) && path
    end

    def app_models
      load_boot_rb
      identity_methods = ORM_IDENTITY_METHODS[Cfg[:orm].to_s.to_sym]
      return [] unless identity_methods
      ObjectSpace.each_object(Class).select do |o|
        identity_methods.all? {|m| o.respond_to?(m)} && model_exists?(o.name)
      end
    end

    def model_exists? name
      path = dst_path(:models, class_to_route(name))
      File.file?(path + MODEL_SUFFIX) && path
    end

    def migrations_by_model model
      Dir[dst_path(:migrations, class_to_route(model), '*' + MIGRATION_SUFFIX)].map do |f|
        File.basename(f)
      end
    end

    private

    def write_file file, data
      o '***    Writing "%s" ***' % unrootify(file).gsub('::', '_')
      File.open(file, 'w') {|f| f << (data.respond_to?(:join) ? data.join : data)}
    end

    def update_file file, data
      o '*** Updating "%s" ***' % unrootify(file)
      File.open(file, 'a+') {|f| f << (data.respond_to?(:join) ? data.join : data)}
    end

    def extract_setup input
      input.scan(/:(.+)/).flatten.last
    end
    module_function :extract_setup

    def unrootify path, root = nil
      root = (root || dst_path.root).gsub(/\/+/, '/')
      regexp = /\A#{Regexp.escape(root)}\/?/
      path.gsub(/\/+/, '/').sub(regexp, '')
    end

    def valid_server? smth
      server = smth.to_s.to_sym
      KNOWN_WEB_SERVERS.include?(server) ? server : false
    end
    module_function :valid_server?

    def valid_orm? smth
      return unless smth.is_a?(String) || smth.is_a?(Symbol)
      case
      when smth =~ /\Aa/i
        :ActiveRecord
      when smth =~ /\Ad/i
        :DataMapper
      when smth =~ /\As/i
        :Sequel
      end
    end
    module_function :valid_orm?

    def valid_db_type? smth
      return unless  smth.is_a?(String) || smth.is_a?(Symbol)
      case
      when smth =~ /\Am/i
        :mysql
      when smth =~ /\Ap/i
        :postgres
      when smth =~ /\As/i
        :sqlite
      end
    end
    module_function :valid_db_type?

    def valid_engine? smth
      engine = smth.to_s.to_sym
      EConstants::VIEW__ENGINE_BY_SYM.has_key?(engine) ? engine : false
    end
    module_function :valid_engine?

    def valid_controller? name
      name.nil? || name.empty? && fail("Please provide controller name")
      ctrl_path = controller_exists?(name) || fail('"%s" controller does not exists' % name)

      ctrl = name.split('::').map(&:to_sym).inject(Object) do |ns,c|
        ctrl_dirname = unrootify(ctrl_path)
        ns.const_defined?(c) || fail("#{ctrl_dirname} exists but #{name} controller not defined.
          Please define it manually or delete #{ctrl_dirname} and start over.")
        ns.const_get(c)
      end
      [ctrl_path, ctrl]
    end

    def valid_route? ctrl_name, name
      ctrl_path, ctrl = valid_controller?(ctrl_name)
      name.nil? || name.empty? && fail("Please provide route name")
      path_rules = ctrl.path_rules.inject({}) do |map,(r,s)|
        map.merge %r[#{Regexp.escape s}] => r.source
      end
      route = action_to_route(name, path_rules)
      validate_route_name(route)
      file = File.join(ctrl_path, route + '.rb')
      [file, route]
    end

    def o *chunks
      @logger ||= Logger.new(STDOUT)
      opts = chunks.last.is_a?(Hash) ? chunks.pop : {}
      @logger << "%s\n" % chunks.join(opts[:join].to_s)
    end
    module_function :o

    def validate_constant_name constant
      constant =~ /[^\w|\d|\:]/ && fail("Wrong constant name - %s, it should contain only alphanumerics" % constant)
      constant =~ /\A[0-9]/     && fail("Wrong constant name - %s, it should start with a letter" % constant)
      constant =~ /\A[A-Z]/     || fail("Wrong constant name - %s, it should start with a uppercase letter" % constant)
      constant
    end
    module_function :validate_constant_name

    def validate_route_name name
      name =~ /\W/ && fail("Routes may contain only alphanumerics")
      name
    end

    def view_setups_for ctrl, action
      boot_app
      ctrl_instance = ctrl.new
      ctrl_instance.respond_to?(action.to_sym) || fail('"%s" route does not exists' % action)
      
      action_name, request_method = deRESTify_action(action)
      ctrl_instance.action_setup  = ctrl.action_setup[action_name][request_method]
      ctrl_instance.call_setups!
      [
        File.join(ctrl_instance.view_path?, ctrl_instance.view_prefix?),
        ctrl_instance.engine_ext?
      ]
    end

    def namespace_to_source_code name
      names, constants = name.split('::'), []
      
      names.uniq.size == names.size ||
        fail('%s namespace constants duplicates' % name)

      names.map(&:to_sym).inject(Object) do |ns,c|
        validate_constant_name(c)
        c_class, next_ns = Module, nil

        if ns && ns.const_defined?(c)
          next_ns = ns.const_get(c)
          c_class = next_ns.class
          [Class, Module].include?(c_class) ||
            fail('%s should be a Class or a Module. It is a %s instead' % [constants.keys*'::', c_class])
        end
        
        constants << [c, c_class.name.downcase]
        next_ns
      end
      
      constant_name = constants.pop.first
      
      before, after = [], []
      constants.each do |(cn,cc)|
        i = INDENT * before.size
        before << '%s%s %s' % [i, cc, cn]
        after  << '%send'   % i
      end
      [before, constant_name, after.reverse << '']
    end

    def constant_defined? name
      return unless name
      namespace = name.split('::').map {|c| validate_constant_name c}
      namespace.inject(Object) do |o,c|
        o.const_defined?(c.to_sym) ? o.const_get(c) : break
      end
    end

    def output_source_code source
      (source.is_a?(String) ? File.readlines(source) : source).each {|l| o "+ " + l.chomp}
    end

  end
end
