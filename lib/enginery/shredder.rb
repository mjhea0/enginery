module Enginery
  class Shredder
    include Helpers
    attr_reader :dst_root

    def initialize dst_root
      @dst_root = dst_root
    end

    def delete_controller name
      name.nil? || name.empty? &&
        fail("Please provide controller name via second argument")
      
      path = dst_path(:controllers, class_to_route(name))
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

  end
end
