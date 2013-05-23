module Enginery
  class Delete
    include Helpers
    attr_reader :dst_root

    def initialize dst_root
      @dst_root = dst_root
    end

    def controller name
      
      controller_path, controller_object = valid_controller?(name)
      
      routes_by_controller(name).each {|r| route(name, r)}
      helper(name)

      if File.exists?(controller_path)
        o
        o '*** Removing "%s" folder ***' % unrootify(controller_path)
        FileUtils.rm_r(controller_path)
      end

      file = controller_path + CONTROLLER_SUFFIX
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end

    end

    def rear_controller model
      
      file = dst_path(:rear_controllers, class_to_route(model) + ADMIN_SUFFIX)
      
      if File.exists?(file)
        o
        o '*** Deleting "%s" file ***' % unrootify(file)
        FileUtils.rm(file)
      end
    end

    def route controller, name
      file, * = valid_route?(controller, name)
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
      view controller, name
      spec controller, name
    end

    def view controller, route
      _, ctrl = valid_controller?(controller)
      path, ext = view_setups_for(ctrl, route)
      file = File.join(path, route + ext)

      return unless File.exists?(file)
      o '*** Deleting "%s" file ***' % unrootify(file)
      o
      FileUtils.rm(file)
    end

    def spec controller, route
      _, controller_object = valid_controller?(controller)
      _, route = valid_route?(controller, route)

      path = dst_path(:specs, class_to_route(controller), '/')
      file = path + route + SPEC_SUFFIX
      return unless File.exists?(file)
      o '*** Deleting "%s" file ***' % unrootify(file)
      o
      FileUtils.rm(file)
    end

    def helper controller
      _, ctrl = valid_controller?(controller)
      file = dst_path(:helpers, class_to_route(controller) + HELPER_SUFFIX)
      return unless File.exists?(file)
      o '*** Deleting "%s" file ***' % unrootify(file)
      o
      FileUtils.rm(file)
    end

    def model name
      name.nil? || name.empty? && fail("Please provide model name")

      file = dst_path(:models, class_to_route(name) + MODEL_SUFFIX)
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
      migrations_by_model(name).each do |m|
        migration m.split('.').first
      end
      rear_controller(name)
      true
    end

    def migration name
      name.nil? || name.empty? && fail("Please provide migration name")
      Dir[dst_path(:migrations, '**/%s.*%s' % [name, MIGRATION_SUFFIX])].each do |file|
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end

  end
end
