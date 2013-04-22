ActiveRecord::Migration.verbose = false

module Enginery
  class TrackingTableMigrator < ActiveRecord::Migration
    def up
      return if table_exists?(TRACKING_TABLE)
      create_table TRACKING_TABLE do |t|
        TRACKING_TABLE__COLUMNS.each {|c| t.string(c)}
      end
      TRACKING_TABLE__INDEXES.each {|c| add_index(TRACKING_TABLE, c)}
    end
  end

  class ZEngineryMigrationTracks < ActiveRecord::Base
  end
end
