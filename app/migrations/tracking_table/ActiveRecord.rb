ActiveRecord::Migration.verbose = false

module Enginery
  class Migrator
    class TracksMigrator < ActiveRecord::Migration
      def up
        return if table_exists?(TRACKING_TABLE)
        create_table TRACKING_TABLE do |t|
          TRACKING_TABLE__COLUMNS.each {|c| t.string(c, limit: 255)}
        end
        TRACKING_TABLE__INDEXES.each {|c| add_index(TRACKING_TABLE, c)}
      end
    end

    class TracksModel < ActiveRecord::Base
      self.table_name = TRACKING_TABLE
    end
  end
end
