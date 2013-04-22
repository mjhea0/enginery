Sequel.extension :migration

module Enginery
  class Migrator
    TracksMigrator = Sequel.migration do
      up do
        create_table? TRACKING_TABLE do
          primary_key :id
          TRACKING_TABLE__COLUMNS.each {|c| column c, String, size: 255}
          TRACKING_TABLE__INDEXES.each {|c| index c}
        end
      end
    end

    class TracksModel < Sequel::Model(TRACKING_TABLE)
    end
  end
end
