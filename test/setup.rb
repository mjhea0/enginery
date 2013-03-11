require 'stringio'
require 'bundler/setup'
Bundler.require

module Enginery
  module Test

    DST_ROOT = (File.expand_path('../sandbox', __FILE__) + '/').freeze
    BIN = File.expand_path('../../bin/enginery', __FILE__).freeze
    
    ORMs = %w[ActiveRecord DataMapper Sequel].freeze
    DB_SETUP = {type: 'mysql', name: 'dev__enginery', user: 'dev'}.freeze
    DB_STR_SETUP = 'db_type:%s db_name:%s db_user:%s' % DB_SETUP.values
    DB = Mysql.new(nil, DB_SETUP[:user])
    
  end
end

Dir['./test/support/*.rb'].each {|f| require f}
