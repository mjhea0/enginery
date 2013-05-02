module Enginery
  class Delete
    include Helpers
    attr_reader :dst_root

    def initialize dst_root
      @dst_root = dst_root
    end

    def controller name
      
      controller_path, controller_object = valid_controller?(name)

      if File.exists?(path)
        o
        o '*** Removing "%s" folder ***' % unrootify(controller_path)
        FileUtils.rm_r(path)
      end

      file = controller_path + CONTROLLER_SUFFIX
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end

      if c = controller_setup_by_path(controller_path)
        c[:routes].each {|r| route(name, r)}
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

    def model name
      name.nil? || name.empty? && fail("Please provide model name")

      file = dst_path(:models, class_to_route(name) + '.rb')
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end

    def migration model, name
      name.nil? || name.empty? && fail("Please provide migration name")

      file = dst_path(:migrations, class_to_route(model), name)
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end



  end
end
