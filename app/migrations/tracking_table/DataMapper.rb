require 'dm-migrations'

module Enginery
  class Migrator
    TracksMigrator = DataMapper::Migration.new 0, TRACKING_TABLE do
      @verbose = false
      up do
        unless DataMapper.repository(repository).adapter.storage_exists?(TRACKING_TABLE.to_s)
          create_table TRACKING_TABLE do
            column :id, Integer, serial: true
            TRACKING_TABLE__COLUMNS.each {|c| column c, String, length: 255}
          end
          TRACKING_TABLE__INDEXES.each {|c| create_index(TRACKING_TABLE, c)}
        end
      end
    end

    class TracksModel
      include DataMapper::Resource
      repositories.each {|r| storage_names[r.name] = TRACKING_TABLE}
      property :id, Serial
      TRACKING_TABLE__COLUMNS.each {|c| property c, String, length: 255}
    end
    DataMapper.finalize
  end
end
