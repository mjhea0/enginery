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

  TRACKING_TABLE = :z__enginery__migrator_tracks
  TRACKING_TABLE__COLUMNS = [:migration, :performed_at, :vector].freeze
  TRACKING_TABLE__INDEXES = [:migration].freeze
end
