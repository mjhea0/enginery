require 'yaml'

class AppConfig
  ENVIRONMENTS = [:development, :test, :production].freeze
  DEFAULT_ENV  = ENVIRONMENTS.first
  attr_reader :path, :db, :env

  def initialize
    @env = (ENV['RACK_ENV'] || DEFAULT_ENV).to_s.to_sym
    ENVIRONMENTS.include?(@env) || raise("#{@env} environment not supported. Please use one of #{ENVIRONMENTS*', '}")
    @env_map = ENVIRONMENTS.inject({}) {|map,e| map.merge(e => e == env)}.freeze

    set_paths Dir.pwd
    set_env env
    load_config
    load_db_config
    @opted_config = {}
  end

  def self.paths
    {
        root: [:config, :base, :public, :var, :tmp],
        base: [:models, :views, :controllers, :helpers, :specs, :migrations],
         var: [:pid, :log],
      public: [:assets],
    }
  end

  # full path to application root,
  # ie. the folder containing base/ public/ var/ etc.
  def root_path *chunks
    File.join(@path[:root], *chunks.map(&:to_s))
  end

  # defining helper methods for paths so it will be possible to use
  # Cfg.foo_path instead of Cfg.path[:foo]
  # see self.paths for available paths, eg. Cfg.config_path, Cfg.assets_path etc.
  # any number of arguments accepted. arguments will be joined by a slash:
  # Cfg.base_path('foo', 'bar') #=> /path/to/app/base/foo/bar
  #
  paths.each_value do |paths|
    paths.each do |p|
      define_method '%s_path' % p do |*chunks|
        File.join(@path[p], *chunks.map(&:to_s))
      end
    end
  end
  alias view_path views_path

  # allow to set custom configs without write them into config.yml
  def []= key, val
    @opted_config[key] = val
  end

  # reading configs set into config.yml or programmatically(via Cfg[:foo] = 'bar')
  def [] config
    @config[config] || @opted_config[config]
  end

  def development?
    @env_map[:development]
  end
  alias dev? development?

  def production?
    @env_map[:production]
  end
  alias prod? production?

  def test?
    @env_map[:test]
  end

  private
  def set_paths root
    path = {:root => (root.to_s + '/').gsub(/\/+/, '/')}
    self.class.paths.each_pair do |ns,paths|
      paths.each do |p|
        path[p] = path[ns] + p.to_s + '/'
      end
    end
    @path = indifferent_params(path).freeze
  end

  def set_env env
    @env = env ? env.to_s.downcase.to_sym : DEFAULT_ENV
  end

  def load_config
    @config = load_file('config.yml').freeze
  end

  def load_db_config
    if url = ENV['DATABASE_URL']
      return @db = {url: url}.freeze
    end
    @db = load_file('database.yml').freeze
  end

  def load_file file
    path = config_path(file)
    data = File.file?(path) ? (YAML.load(File.read(path)) rescue nil) : nil
    return indifferent_params(data[@env] || data[@env.to_s]) if data.is_a?(Hash)
    warn '"%s" does not exists or is not a valid YAML file' % file
    {}
  end

  # Enable string or symbol key access to the nested params hash.
  def indifferent_params(object)
    case object
    when Hash
      new_hash = indifferent_hash
      object.each { |key, value| new_hash[key] = indifferent_params(value) }
      new_hash
    when Array
      object.map { |item| indifferent_params(item) }
    else
      object
    end
  end

  # Creates a Hash with indifferent access.
  def indifferent_hash
    Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
  end
end
Cfg = AppConfig.new
