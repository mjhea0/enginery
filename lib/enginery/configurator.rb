module Enginery
  class Configurator
    include Helpers

    def initialize dst_root, setups = {}, &proc
      @dst_root, @setups = dst_root, setups||{}
      @setups.is_a?(Hash) || fail('setups should be a Hash. A %s given instead' % @setups.class)
      self.instance_exec(&proc) if block_given?
    end

    def update_config_yml
      setups = normalize_setups(@setups)

      setups.delete 'db'

      engine = setups['engine'] || EConstants::VIEW__DEFAULT_ENGINE_NAME
      path = src_path(:layouts, engine)
      if File.directory?(path)
        Dir[path + '/*'].each {|f| FileUtils.cp(f, dst_path.views)}
        setups['layout'] = 'layout'
      end

      return if setups.empty?

      yml = YAML.load File.read(dst_path.config_yml)
      ENVIRONMENTS.each do |env|
        (cfg = yml[env] || yml[env.to_s]) && cfg.update(setups)
      end
      o
      write_file dst_path.config_yml, YAML.dump(yml)
      output_source_code YAML.dump(setups).split("\n")
    end

    def update_gemfile
      return if @setups.empty?

      gems, gemfiles = [], []
      target_gems = File.file?(dst_path.Gemfile) ?
        extract_gems(File.read dst_path.Gemfile) : []
      
      @setups.values_at(:orm, :engine, :server).compact.each do |klass|
        gemfiles << [src_path(:gemfiles, '%s.rb' % klass), klass]
      end
      if orm = @setups[:orm]
        db_type = (@setups[:db]||{})[:type] || DEFAULT_DB_TYPE
        gemfiles << [src_path(:gemfiles, db_type, '%s.rb' % orm)]
      end
      gemfiles.each do |(gemfile,gem)|
        if File.file?(gemfile)
          File.readlines(gemfile).each do |l|
            extract_gems(l).each do |g|
              gems << l.chomp unless target_gems.include?(g)
            end
          end
        else
          next unless gem
          gem = class_to_gem(gem)
          gems << ("gem '%s'" % gem) unless target_gems.include?(gem)
        end
      end
      return if gems.empty?
      o
      source_code = ['', *gems, '']
      update_file dst_path.Gemfile, source_code.join("\n")
      output_source_code source_code
    end

    def update_rakefile
      test_framework = @setups[:test_framework] || DEFAULT_TEST_FRAMEWORK
      source_file = src_path(:rakefiles, "#{test_framework}.rb")
      unless File.file?(source_file)
        o("%s not in the list of supported test frameworks: %s" % [
          test_framework,
          Dir[src_path(:rakefiles, '*.rb')].map {|f| f.sub(/\.rb\Z/, '')}*', '
        ])
      end
      source_code = File.readlines(source_file)
      
      if orm = @setups[:orm]
        source_file = src_path(:rakefiles, '%s.rb' % orm)
        source_code.concat  File.readlines(source_file)
      end
      o
      update_file dst_path.Rakefile, source_code
      output_source_code(source_code)
    end

    def update_boot_rb
    end

    def update_database_rb
      if orm = @setups[:orm]
        source_file = src_path(:database, '%s.rb' % orm)
        source_code = File.readlines(source_file)
        o
        update_file dst_path.database_rb, source_code
        output_source_code(source_code)
      end
    end

    def update_database_yml
      setups = normalize_setups(@setups[:db])
      type   = setups['type'] || DEFAULT_DB_TYPE
      yml    = YAML.load File.read(src_path(:database, '%s.yml' % type))
      ENVIRONMENTS.each do |env|
        (cfg = yml[env] || yml[env.to_s]) && cfg.update(setups)
      end
      o
      write_file dst_path.database_yml, YAML.dump(yml)
      setups['pass'] = '___________' if setups['pass']
      output_source_code(YAML.dump(setups).split("\n")) if setups.any?
    end

    private
    def class_to_gem klass
      underscore klass.to_s
    end

    def extract_gems string
      string.split("\n").inject([]) do |gems,l|
        l.strip!
        (l =~ /\Agem/) &&
          (gem = l.scan(/\Agem\s+([^,]*)/).flatten.first) &&
          (gems << gem.gsub(/\A\W+|\W+\Z/, ''))
        gems
      end
    end
    
    def normalize_setups setups = {}
      (setups||{}).inject({}) do |s,(k,v)|
        key, val = k.to_s, v
        val = val.to_i if v.respond_to?(:match) && v.match(/\A\d+\Z/)
        val = val.to_s if val.is_a?(Symbol)
        s.merge key => val
      end
    end

  end
end
