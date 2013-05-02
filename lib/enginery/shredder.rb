module Enginery
  class Shredder

    include Helpers
    attr_reader :dst_root

    def initialize dst_root
      @dst_root = dst_root
    end

    def delete_controller name
      path, * = valid_controller?(name)

      if File.exists?(path)
        o
        o '*** Removing "%s" folder ***' % unrootify(path)
        FileUtils.rm_r(path)
      end

      file = path + '_controller.rb'
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end

    def delete_route controller, name
      file, * = valid_route?(controller, name)
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end

    def delete_view controller, route
      _, ctrl = valid_controller?(controller)
      path, ext = view_setups_for(ctrl, route)
      file = File.join(path, route + ext)
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end

    def delete_model name
      name.nil? || name.empty? && fail("Please provide model name")

      file = dst_path(:models, class_to_route(name) + '.rb')
      if File.exists?(file)
        o '*** Deleting "%s" file ***' % unrootify(file)
        o
        FileUtils.rm(file)
      end
    end

    def delete_migrations model
      model.nil? || model.empty? && fail("Please provide model name")

      path = dst_path(:migrations, class_to_route(model))
      
      o '*** Removing "%s" file ***' % unrootify(path)
      o
      FileUtils.rm_r(path)
    
    end

    def delete_migration model, name
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
