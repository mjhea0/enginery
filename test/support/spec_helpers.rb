module Enginery
  module Test
    module SpecHelper

      def new_app args
        %x[#{BIN} g #{args} #{DB_STR_SETUP}]
      end
      
      def new_controller args
        %x[#{BIN} g:c #{args}]
      end
      alias new_controllers new_controller

      def delete_controller name
        %x[#{BIN} delete:c:y #{name}]
      end

      def new_route args
        %x[#{BIN} g:r #{args}]
      end
      alias new_routes new_route

      def delete_route args
        %x[#{BIN} delete:r:y #{args}]
      end

      def new_view args
        %x[#{BIN} g:v #{args}]
      end

      def delete_view args
        %x[#{BIN} delete:v:y #{args}]
      end

      def new_model args
        %x[#{BIN} g:m #{args}]
      end
      alias new_models new_model

      def delete_model args
        %x[#{BIN} delete:mo:y #{args}]
      end

      def new_helper args
        %x[#{BIN} g:h #{args}]
      end
      alias new_helpers new_helper

      def delete_helper args
        %x[#{BIN} delete:h:y #{args}]
      end

      def new_spec args
        %x[#{BIN} g:s #{args}]
      end
      alias new_specs new_spec

      def delete_spec args
        %x[#{BIN} delete:s:y #{args}]
      end

      def new_test args = nil
        args ? %x[rake test:#{args}] : %x[rake]
      end

      def all_tests
        %x[rake]
      end

      def new_migration args
        %x[#{BIN} migration #{args}]
      end

      def delete_migration args
        %x[#{BIN} delete:mi:y #{args}]
      end

      def new_admin_controller args
        %x[#{BIN} g:admin #{args}]
      end

      def delete_admin_controller args
        %x[#{BIN} delete:admin:y #{args}]
      end

      def migrate_up! args, force_run = false
        %x[#{BIN} migrate:up#{':f' if force_run} #{args}]
      end

      def migrate_down! args, force_run = false
        %x[#{BIN} migrate:down#{':f' if force_run} #{args}]
      end

      def ok? output
        ($? && $?.exitstatus == 0) || fail(output)
        yield(output) if block_given?
        true
      end

      def fail? output, expected_output = nil
        check($?.exitstatus) > 0 if $?
        check(output) =~ expected_output if expected_output.is_a?(Regexp)
        check(output) == expected_output if expected_output.is_a?(String)
        true
      end
      alias fail_with? fail?

      def skipped? output
        output =~ /skip/i
      end
      
      def cleanup
        FileUtils.rm_rf DST_ROOT + 'App'
        DB.query 'drop   database ' + DB_SETUP[:name]
        DB.query 'create database ' + DB_SETUP[:name]
      end

      def table table
        DB.query 'select * from %s.%s' % [DB_SETUP[:name], table]
      end

      def column table, column
        check(table).is_a? Mysql::Result
        table.fetch_fields.find {|f| f.name == column}
      end

      def has_column table, column, type = nil
        column = column(table, column)
        does(column).respond_to? :type
        case type
        when :string
          check(column.type) == 253
        when :text
          check(column.type) == 252
        end
        true
      end
      alias has_column? has_column

      def has_no_column table, column
        is( column(table, column) ).nil?
      end

      def contain? file, regexp
        is(File).file? file
        expect {File.read file} =~ regexp
      end

    end
  end
end
