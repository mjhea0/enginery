Dir.chdir File.expand_path('../..', __FILE__) do # load application from any location
  require 'bundler/setup'
  Bundler.require(:default)

  require './base/config'
  Bundler.require(Cfg.env)
end

require Cfg.base_path('database.rb')

App = E.new :automount do
  map hosts: Cfg[:hosts]

  controllers_setup do
    view_path 'base/views'
    layout Cfg[:layout] if Cfg[:layout]
    engine Cfg[:engine].to_sym if Cfg[:engine]
    format Cfg[:format] if Cfg[:format]
  end

  assets_url 'assets'
  assets.prepend_path Cfg.assets_path

  if Cfg.dev?
    use Rack::CommonLogger
    use Rack::ShowExceptions
  end

  on_boot do
    defined?(Rear) && (url = Cfg[:admin_url]) && mount(Rear.controllers, url)
    defined?(DataMapper) && DataMapper.finalize
  end
end

# loading helpers
require Cfg.helpers_path('application_helpers')
Dir[Cfg.helpers_path('**/*.rb')].each {|f| require f}

# loading models
Dir[Cfg.models_path('**/*.rb')].each {|f| require f}

# loading controllers
%w[**/*_controller.rb **/*.rb].each do |m|
  Dir[Cfg.controllers_path(m)].each {|f| require f}
end
