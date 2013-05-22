module Enginery
  module Helpers

    def in_app_folder?
      File.directory?(dst_path.controllers)
    end

    def fail_unless_in_app_folder!
      in_app_folder? || fail("Seems current folder does not contain a Espresso application")
    end

    def fail *failures
      throw :enginery_failures, Failure.new(*failures)
    end
    module_function :fail

    def fail_verbosely *failures
      o *failures
      fail *failures
    end
    module_function :fail_verbosely

    def valid_server? smth
      server = smth.to_s.to_sym
      KNOWN_WEB_SERVERS.include?(server) ? server : false
    end
    module_function :valid_server?

    def valid_orm? smth
      return unless smth.is_a?(String) || smth.is_a?(Symbol)
      case
      when smth =~ /\Aa/i
        :ActiveRecord
      when smth =~ /\Ad/i
        :DataMapper
      when smth =~ /\As/i
        :Sequel
      end
    end
    module_function :valid_orm?

    def valid_db_type? smth
      return unless  smth.is_a?(String) || smth.is_a?(Symbol)
      case
      when smth =~ /\Am/i
        :mysql
      when smth =~ /\Ap/i
        :postgres
      when smth =~ /\As/i
        :sqlite
      end
    end
    module_function :valid_db_type?

    def valid_engine? smth
      engine = smth.to_s.to_sym
      EConstants::VIEW__ENGINE_BY_SYM.has_key?(engine) ? engine : false
    end
    module_function :valid_engine?

    def valid_controller? name
      name.nil? || name.empty? && fail("Please provide controller name")
      ctrl_path = controller_exists?(name) || fail('"%s" controller does not exists' % name)

      ctrl = name.split('::').map(&:to_sym).inject(Object) do |ns,c|
        ctrl_dirname = unrootify(ctrl_path)
        ns.const_defined?(c) || fail("#{ctrl_dirname} exists but #{name} controller not defined.
          Please define it manually or delete #{ctrl_dirname} and start over.")
        ns.const_get(c)
      end
      [ctrl_path, ctrl]
    end

    def valid_route? ctrl_name, name
      ctrl_path, ctrl = valid_controller?(ctrl_name)
      name.nil? || name.empty? && fail("Please provide route name")
      path_rules = ctrl.path_rules.inject({}) do |map,(r,s)|
        map.merge %r[#{Regexp.escape s}] => r.source
      end
      route = action_to_route(name, path_rules)
      validate_route_name(route)
      file = File.join(ctrl_path, route + '.rb')
      [file, route]
    end

    def validate_constant_name constant
      constant =~ /[^\w|\d|\:]/ && fail("Wrong constant name - %s, it should contain only alphanumerics" % constant)
      constant =~ /\A[0-9]/     && fail("Wrong constant name - %s, it should start with a letter" % constant)
      constant =~ /\A[A-Z]/     || fail("Wrong constant name - %s, it should start with a uppercase letter" % constant)
      constant
    end
    module_function :validate_constant_name

    def validate_route_name name
      name =~ /\W/ && fail("Routes may contain only alphanumerics")
      name
    end


  end
end
