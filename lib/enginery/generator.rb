module Enginery
  class Generator
    
    include Helpers
    attr_reader :dst_root, :setups

    def initialize dst_root, setups = {}
      @dst_root, @setups = dst_root, setups
    end

    def generate_project name = nil
      name = name.to_s

      if name.empty?
        name = '.'
      else
        name =~ /\.\.|\// && fail('Project name can not contain "/" nor ".."')
        @dst_root, @dst_path_map = File.join(@dst_root, name, ''), nil
      end

      Dir[dst_path(:root, '*')].any? && fail('"%s" should be a empty folder' % dst_path.root)

      o
      o '=== Generating "%s" project ===' % name

      folders, files = Dir[src_path(:base, '**/{*,.[a-z]*}')].partition do |entry|
        File.directory?(entry)
      end

      FileUtils.mkdir_p dst_path.root
      o "#{name}/"
      folders.each do |folder|
        path = unrootify(folder, src_path.base)
        o "  D  #{path}/"
        FileUtils.mkdir_p dst_path(:root, path)
      end

      files.reject {|f| File.basename(f) == '.gitkeep'}.each do |file|
        path = unrootify(file, src_path.base)
        o "  F  #{path}"
        FileUtils.cp file, dst_path(:root, path)
      end

      Configurator.new dst_root, setups do
        update_gemfile
        update_rakefile
        update_boot_rb
        update_config_yml
        update_database_rb
        update_database_yml
      end
      name
    end

    def generate_controller name

      name.nil? || name.empty? && fail("Please provide controller name")
      before, ctrl_name, after = namespace_to_source_code(name)

      source_code, i = [], INDENT * before.size
      before.each {|s| source_code << s}
      source_code << "#{i}class #{ctrl_name} < E"
      
      (@setups[:include] || []).each do |mdl|
        source_code << "#{i + INDENT}include #{mdl}"
      end
    
      source_code << "#{i + INDENT}# controller-wide setups"

      if route = setups[:route]
        source_code << "#{i + INDENT}map '#{route}'"
      end
      if engine = setups[:engine]
        source_code << "#{i + INDENT}engine :#{engine}"
        Configurator.new(dst_root, engine: engine).update_gemfile
      end
      if format = setups[:format]
        source_code << "#{i + INDENT}format '#{format}'"
      end
      source_code << INDENT
      
      source_code << "#{i}end"
      after.each  {|s| source_code << s}
      
      path = dst_path(:controllers, class_to_route(name))
      file = path + '_controller.rb'
      File.exists?(file) && fail('"%s" controller already exists' % name)
      o
      o '=== Generating "%s" controller ===' % name
      o '***   Creating "%s/" ***' % unrootify(path)
      FileUtils.mkdir_p(path)
      
      write_file file, source_code.join("\n")
      output_source_code source_code
      ctrl_name
    end

    def generate_route ctrl_name, name

      action_file, action = valid_route?(ctrl_name, name)

      File.exists?(action_file) && fail('"%s" route already exists' % name)

      before, ctrl_name, after = namespace_to_source_code(ctrl_name)

      source_code, i = [], '  ' * before.size
      before.each {|s| source_code << s}
      source_code << "#{i}class #{ctrl_name}"
      source_code << "#{i + INDENT}# action-specific setups"
      source_code << ''

      if format = setups[:format]
        source_code << "#{i + INDENT}format_for :#{action}, '#{format}'"
      end
      if setups.reject {|k,v| k == :route}.any?
        source_code << "#{i + INDENT}before :#{action} do"
        if engine = setups[:engine]
          source_code << "#{i + INDENT*2}engine :#{engine}"
          Configurator.new(dst_root, engine: engine).update_gemfile
        end
        source_code << "#{i + INDENT}end"
        source_code << ""
      end

      source_code << (i + INDENT + "def #{action}")
      action_source_code = ["render"]
      if block_given?
        action_source_code = yield
        action_source_code.is_a?(Array) || action_source_code = [action_source_code]
      end
      action_source_code.each do |line|
        source_code << (i + INDENT*2 + line.to_s)
      end
      source_code << (i + INDENT + "end")
      source_code << ''

      source_code << "#{i}end"
      after.each  {|s| source_code << s}

      o
      o '=== Generating "%s" route ===' % name
      
      write_file action_file, source_code.join("\n")
      output_source_code source_code
      action
    end

    def generate_view ctrl_name, name

      _, action = valid_route?(ctrl_name, name)
      _, ctrl   = valid_controller?(ctrl_name)
      path, ext = view_setups_for(ctrl, action)

      o
      o '=== Generating "%s" view ===' % name
      if File.exists?(path)
        File.directory?(path) || fail('"%s" should be a directory' % unrootify(path))
      else
        o '***   Creating "%s/" ***' % unrootify(path)
        FileUtils.mkdir_p(path)
      end
      file = File.join(path, action + ext)
      o '***   Touching "%s" ***' % unrootify(file)
      FileUtils.touch file
      file
    end

    def generate_model name

      name.nil? || name.empty? && fail("Please provide model name")
      before, model_name, after = namespace_to_source_code(name)
      
      superclass, insertions = '', []
      if orm = valid_orm?(setups[:orm] || Cfg[:orm])
        orm == :ActiveRecord && superclass = ' < ActiveRecord::Base'
        orm == :Sequel       && superclass = ' < Sequel::Model'
        orm == :DataMapper   && insertions << 'include DataMapper::Resource'
        
        (@setups[:include] || []).each do |mdl|
          insertions << "include #{mdl}"
        end
        insertions << ''

        orm == :DataMapper && insertions << 'property :id, Serial'
      end
      insertions << ''

      source_code, i = [], INDENT * before.size
      before.each {|s| source_code << s}
      source_code << "#{i}class #{model_name + superclass}"

      insertions.each do |line|
        source_code << (i + INDENT + line.to_s)
      end

      source_code << "#{i}end"
      after.each  {|s| source_code << s}
      source_code = source_code.join("\n")
      
      file = dst_path(:models, class_to_route(name) + '.rb')
      File.exists?(file) && fail('"%s" file already exists' % unrootify(file))
      
      o
      o '=== Generating "%s" model ===' % name
      dir = File.dirname(file)
      if File.exists?(dir)
        File.directory?(dir) || fail("#{unrootify dir} should be a directory")
      else
        o '***   Creating "%s/" ***' % unrootify(dir)
        FileUtils.mkdir_p(dir)
      end
      
      write_file file, source_code
      output_source_code source_code.split("\n")
      model_name
    end

    def generate_spec ctrl_name, name

      context = {}
      _, context[:controller] = valid_controller?(ctrl_name)
      _, context[:action] = valid_route?(ctrl_name, name)
      context[:spec] = [ctrl_name, context[:action]]*'#'

      o
      o '=== Generating "%s#%s" spec ===' % [ctrl_name, name]
      path = dst_path(:specs, class_to_route(ctrl_name), '/')
      if File.exists?(path)
        File.directory?(path) || fail("#{path} should be a directory")
      else
        o '***   Creating "%s" ***' % unrootify(path)
        FileUtils.mkdir_p(path)
      end

      file = path + context[:action] + SPEC_SUFFIX
      File.exists?(file) && fail('%s already exists' % unrootify(file))
      
      test_framework = setups[:test_framework] || DEFAULT_TEST_FRAMEWORK
      engine = Tenjin::Engine.new(path: [src_path.specfiles], cache: false)
      source_code = engine.render(test_framework.to_s + '.erb', context)

      write_file file, source_code
      output_source_code source_code.split("\n")
      file
    end

  end
end
