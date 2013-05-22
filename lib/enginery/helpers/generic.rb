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
        paths = { :root => File.expand_path('../../../../app', __FILE__) + '/' }
        [
          :base,
          :gemfiles,
          :rakefiles,
          :specfiles,
          :database,
          :migrations,
          :layouts,
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

    def unrootify path, root = nil
      root = (root || dst_path.root).gsub(/\/+/, '/')
      regexp = /\A#{Regexp.escape(root)}\/?/
      path.gsub(/\/+/, '/').sub(regexp, '')
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

    def o *chunks
      @logger ||= Logger.new(STDOUT)
      opts = chunks.last.is_a?(Hash) ? chunks.pop : {}
      @logger << "%s\n" % chunks.join(opts[:join].to_s)
    end
    module_function :o

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
      
      constant_name = constants.pop.first.to_s
      
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
      namespace = name.to_s.strip.sub(/\A::/, '').split('::').map {|c| validate_constant_name c}
      namespace.inject(Object) do |o,c|
        o.const_defined?(c.to_sym) ? o.const_get(c) : break
      end
    end

    def output_source_code source
      (source.is_a?(String) ? File.readlines(source) : source).each {|l| o "+ " + l.chomp}
    end

  end
end
