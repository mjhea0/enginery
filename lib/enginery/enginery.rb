module Enginery
  ENVIRONMENTS = [:development, :test, :production].freeze
  DEFAULT_TEST_FRAMEWORK = :Specular
  DEFAULT_DB_TYPE = :sqlite
  INDENT = (' ' * 2).freeze
  KNOWN_WEB_SERVERS = %w[
    WEBrick
    Thin
    Unicorn
    Rainbows
    Puma
    Reel
    Mongrel
    FastCGI
    SCGI
  ].map(&:to_sym).freeze

  # using z_ prefix to make sure tracking table shown last
  # when some database management tools used.
  TRACKING_TABLE = :z_enginery_migrator_tracks
  TRACKING_TABLE__COLUMNS = [:migration, :performed_at, :vector].freeze
  TRACKING_TABLE__INDEXES = [:migration].freeze

  CONTROLLER_SUFFIX = '_controller.rb'.freeze
  ROUTE_SUFFIX      = '.rb'.freeze
  SPEC_SUFFIX       = '_spec.rb'.freeze
  MODEL_SUFFIX      = '.rb'.freeze
  MIGRATION_SUFFIX  = '.rb'.freeze
end
