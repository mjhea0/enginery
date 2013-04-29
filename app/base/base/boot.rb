require 'bundler/setup'
Bundler.require(:default)

require File.expand_path('../config', __FILE__)
Bundler.require(Cfg.env)

require Cfg.base_path('database.rb')

App = E.new :automount do
  
  controllers_setup do
    view_path 'base/views'
    engine(Cfg[:engine].to_sym) if Cfg[:engine]
    format(Cfg[:format]) if Cfg[:format]
  end

  assets_url 'assets'
  assets.prepend_path Cfg.assets_path

  if Cfg.dev?
    use Rack::CommonLogger
    use Rack::ShowExceptions
  end
end

# loading helpers
Dir[Cfg.helpers_path('**/*.rb')].each {|f| require f}

# loading models
%w[**/*.rb].each do |m|
  Dir[Cfg.models_path(m)].each {|f| require f}
end

# loading controllers
%w[**/*_controller.rb **/*.rb].each do |m|
  Dir[Cfg.controllers_path(m)].each {|f| require f}
end
