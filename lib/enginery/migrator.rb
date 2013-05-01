module Enginery
  class Migrator
    include Helpers

    TIME_FORMAT = '%Y-%m-%d_%H-%M-%S'.freeze
    NAME_REGEXP = /\A(\d+)\.(\d+\-\d+\-\d+_\d+\-\d+\-\d+)\.(.*)\.rb\Z/.freeze

    def initialize dst_root, setups = {}
      @dst_root, @setups = dst_root, setups
      @migrations = Dir[dst_path(:migrations, '**/*.rb')].inject([]) do |map,f|
        step, time, name = File.basename(f).scan(NAME_REGEXP).flatten
        step && time && name && map << [step.to_i, time, name, f.sub(dst_path.migrations, '')]
        map
      end.sort {|a,b| a.first <=> b.first}.freeze
    end

    # generate new migration.
    # it will create a [n].[timestamp].[name].rb migration file in base/migrations/
    # and column_transitions.yml file in base/migrations/track/
    # migration file will contain "up" and "down" sections.
    # column_transitions file will keep track of column type changes.
    #
    def new name
      (name.nil? || name.empty?) && fail("Please provide migration name via second argument")
      (name =~ /[^\w|\d|\-|\.|\:]/) && fail("Migration name can contain only alphanumerics, dashes, semicolons and dots")
      @migrations.any? {|m| m[2] == name} && fail('"%s" migration already exists' % name)
      
      context = {name: name, step: @migrations.size + 1}
      model   = @setups[:create_table] || @setups[:update_table]
      [:create_table, :update_table].each do |o|
        context[o] = (m = constant_defined?(@setups[o])) ? model_to_table(m) : nil
      end
      [:create_columns, :update_columns].each do |o|
        context[o] = (@setups[o]||[]).map {|(n,t)| [n, opted_column_type(t)]}
      end
      context[:rename_columns] = @setups[:rename_columns]||[]

      if table = context[:create_table]
        columns = context[:create_columns]
      elsif table = context[:update_table]
        columns = (cc = context[:create_columns]).any? ? cc : context[:update_columns]
      else
        fail('No model provided or provided one does not exists!')
      end

      update_model_file(model, context)
      handle_transitions(table, columns)

      engine = Tenjin::Engine.new(path: [src_path.migrations], cache: false)
      source_code = engine.render("#{guess_orm}.erb", context)
      o
      o '--- %s model - generating "%s" migration ---' % [model, name]
      o
      o '  Serial Number: %s' % context[:step]
      o
      time = Time.now.strftime(TIME_FORMAT)
      path = dst_path(:migrations, class_to_route(model))
      FileUtils.mkdir_p(path)
      file = File.join(path, [context[:step], time, name, 'rb']*'.')
      write_file file, source_code
      output_source_code source_code.split("\n")
    end

    # convert given range or a single migration into files to be run
    # ex: 1-5 will run migrations from one to 5 inclusive
    #     1 2 4 will run 1st, 2nd, and 4th migrations
    #     2 will run only 2nd migration
    def serials_to_files vector, *serials
      vector = validate_vector(vector)
      serials.map do |serial|
        if serial =~ /\-/
          a, z = serial.split('-')
          (a..z).to_a
        else
          serial
        end
      end.flatten.map do |e|
        @migrations.find {|m| m.first == e.to_i} ||
          fail('Wrong range provided. "%s" is not a recognized migration step' % e)
      end.sort do |a,b|
        vector == :up ? a.first <=> b.first : b.first <=> a.first
      end.map(&:last)
    end

    # - validate migration file name
    # - apply migration in given direction if migration was not previously performed
    #   in given direction or :force option given
    # - create a track in TRACKING_TABLE
    #   so on consequent requests we may know whether migration was already performed
    def run vector, file, force_run = nil
      vector = validate_vector(vector)
      
      (migration = @migrations.find {|m| m.last == file}) ||
        fail('"%s" is not a valid migration file' % file)
      
      create_tracking_table_if_needed

      track = track_exists?(file, vector)
      if track && !force_run
        o
        o '*** Skipping "%s: %s" migration ***' % [migration[0], migration[2]]
        o '  It was already performed %s on %s' % [track.vector.upcase, track.performed_at]
        o '  Use :force option to run it anyway - enginery m:%s:force ...' % vector
        o
        return
      end
      apply!(migration, vector) && persist_track(file, vector)
    end

    # list available migrations with date of last run, if any
    def list
      create_tracking_table_if_needed
      o indent('--'), '-=---'
      @migrations.each do |(step,time,name,file)|
        track = track_exists?(File.basename(file))
        last_perform = track ? '%s on %s' % [track.vector, track.performed_at] : 'none'
        o indent(step), ' : ', name
        o indent('created at'), ' : ', DateTime.strptime(time, TIME_FORMAT).rfc2822
        o indent('last performed'), ' : ', last_perform
        o indent('--'), '-=---'
      end
    end

    def outstanding_migrations vector
      create_tracking_table_if_needed
      serials = @migrations.inject([]) do |l,(step,time,name,file)|
        track_exists?(File.basename(file), vector) ? l : l.push(step)
      end
      serials_to_files(vector, *serials)
    end

    private

    # load migration file and call corresponding methods that will run migration up/down
    def apply! migration, vector, orm = guess_orm
      o
      o '*** Performing %s step #%s ***' % [vector, migration.first]
      o '     Label: %s' % migration[2]
      o '       ORM: %s' % orm
      begin
        
        load dst_path(:migrations, migration.last)

        case orm
        when :DataMapper
          MigratorInstance.instance_exec do
            # when using perform_up/down DataMapper will create a tracking table
            # and decide whether migration should be run, based on needs_up? and needs_down?
            # Enginery keeps own tracks and does not need DataMapper's tracking table
            # nor decisions on running migrations,
            # so using instance_exec to apply migrations directly.
            if action = instance_variable_get('@%s_action' % vector)
              action.call
            end
          end
        when :ActiveRecord
          MigratorInstance.new.send vector
        when :Sequel
          MigratorInstance.apply DB, vector
        end
        o '    status: OK'
        true
      rescue => e
        fail e.message, *e.backtrace
      end
    end

    def update_model_file model, context
      return unless guess_orm == :DataMapper
      file = dst_path(:models, class_to_route(model) + '.rb')
      return unless File.file?(file)

      lines, properties = File.readlines(file), []
      lines.each_with_index do |l,i|
        property = l.scan(/(\s+)?property\s+[\W]?(\w+)\W+(\w+)(.*)/).flatten
        properties << (property << i) if property[1] && property[2]
      end
      return if properties.empty?
      property_setup = nil
      
      new_properties = []
      context[:create_columns].each do |(n,t)|
        next if properties.find {|p| p[1].to_s == n.to_s}
        property_setup = [properties.last.first, n, t.to_s.split('::').last]
        new_properties << '%sproperty :%s, %s' % property_setup
      end
      if new_properties.any?
        lines[properties.last.last] += (new_properties.join("\n") + "\n")
      end
        
      context[:rename_columns].each do |(cn,nn)|
        next unless property = properties.find {|p| p[1].to_s == cn.to_s}
        property_setup = [property[0], nn, *property[2..3]]
        lines[property.last] = "%sproperty :%s, %s%s\n" % property_setup
      end

      context[:update_columns].each do |(n,t)|
        next unless property = properties.find {|p| p[1].to_s == n.to_s}
        property_setup = [*property[0..1], t.to_s.split('::').last, property[3]]
        lines[property.last] = "%sproperty :%s, %s%s\n" % property_setup
      end
      return unless property_setup
      File.open(file, 'w') {|f| f << lines.join}
    end

    def handle_transitions table, columns
      transitions_file = dst_path(:migrations, 'transitions.yml')
      transitions = File.file?(transitions_file) ? (YAML.load(File.read(transitions_file)) rescue {}) : {}
      transitions[table] ||= {}
      columns.each do |column|
        column << transitions[table][column.first]
        transitions[table][column.first] = column[1]
      end
      File.open(transitions_file, 'w') {|f| f << YAML.dump(transitions)}
    end

    def create_tracking_table_if_needed
      require src_path(:migrations, 'tracking_table/%s.rb' % guess_orm)
      case guess_orm
      when :DataMapper
        TracksMigrator.instance_exec { @up_action.call }
      when :ActiveRecord
        TracksMigrator.new.up
      when :Sequel
        TracksMigrator.apply DB, :up
      end
    end

    def track_exists? migration, vector = nil
      conditions = {migration: migration}
      conditions[:vector] = vector.to_s if vector # #to_s required on Sequel
      case guess_orm
      when :ActiveRecord, :DataMapper
        TracksModel.first(conditions: conditions)
      when :Sequel
        TracksModel.first(conditions)
      end
    end

    def persist_track migration, vector
      key = {migration: migration}
      row = key.merge(performed_at: DateTime.now.rfc2822, vector: vector.to_s)
      case guess_orm
      when :DataMapper
        TracksModel.all(key).destroy!
        TracksModel.create(row)
      when :ActiveRecord
        TracksModel.delete_all(key)
        TracksModel.create(row)
      when :Sequel
        TracksModel.where(key).delete
        TracksModel.insert(row)
      end
    end

    # get the actual db table of a given model
    def model_to_table model
      case guess_orm
      when :DataMapper
        model.repository.adapter.resource_naming_convention.call(model)
      when :ActiveRecord, :Sequel
        model.table_name
      end
    end

    def default_column_type orm = guess_orm
      case orm
      when :ActiveRecord
        'string'
      when :DataMapper, :Sequel
        'String'
      end
    end

    # convert given string into column type suitable for migration file
    def opted_column_type type, orm = nil
      orm  ||= guess_orm
      type ||= default_column_type(orm)
      case orm
      when :DataMapper
        constant_name = 'DataMapper::Property::%s' % capitalize(type)
        constant_defined?(constant_name) || ("'%s'" % type)
      when :Sequel
        type.to_s =~ /text/i ? "String, text: true" : capitalize(type)
      else
        type
      end
    end

    # someString.capitalize will return Somestring.
    # we need SomeString instead, which is returned by this method
    def capitalize smth
      smth.to_s.match(/(\w)(.*)/) {|m| m[1].upcase << m[2]}
    end

    def guess_orm
      (@setups[:orm] || Cfg[:orm] || fail('No project-wide ORM detected.
        Please update config/config.yml by adding "orm: [:DataMapper|:ActiveRecord|:Sequel]"
        or provide it via orm option - orm:[ar|dm|sq]')).to_sym
    end

    def validate_vector vector
      invalid_vector!(vector) unless vector.is_a?(String)
      (vector =~ /\Au/i) && (vector = :up)
      (vector =~ /\Ad/i) && (vector = :down)
      invalid_vector!(vector) unless vector.is_a?(Symbol)
      vector
    end

    def invalid_vector! vector
      fail('%s is a unrecognized vector. Use either "up" or "down"' % vector.inspect)
    end
    
    def indent smth
      string = smth.to_s
      ident_size = 20 - string.size
      ident_size =  0 if ident_size < 0
      INDENT + ' '*ident_size + string
    end

  end
end
