module Enginery
  module Helpers

    def load_boot_rb
      pv, $VERBOSE = $VERBOSE, nil
      orig = Array.new($:)
      # loading app
      load dst_path.boot_rb
      # for some reason, Bundler get rid of existing loadpath entries.
      # usually this will break autoloading, so storing orig paths and inserting them back
      orig.each {|p| $:.include?(p) || $: << p}
    ensure
      $VERBOSE = pv
    end

    def boot_app
      load_boot_rb
      App.boot!
    end

    def app_controllers
      App.mounted_controllers.select {|c| controller_exists?(c.name)}
    end

    def routes_by_controller controller
      Dir[dst_path(:controllers, class_to_route(controller), '*' + ROUTE_SUFFIX)].map do |f|
        File.basename(f, File.extname(f))
      end
    end
    
    def controller_exists? name
      path = dst_path(:controllers, class_to_route(name))
      File.file?(path + CONTROLLER_SUFFIX) && path
    end

    def model_exists? name
      path = dst_path(:models, class_to_route(name))
      File.file?(path + MODEL_SUFFIX) && path
    end

    def app_models
      load_boot_rb
      identity_methods = ORM_IDENTITY_METHODS[Cfg[:orm].to_s.to_sym]
      return [] unless identity_methods
      ObjectSpace.each_object(Class).select do |o|
        identity_methods.all? {|m| o.respond_to?(m)} && model_exists?(o.name)
      end
    end

    def migrations_by_model model
      Dir[dst_path(:migrations, class_to_route(model), '*' + MIGRATION_SUFFIX)].map do |f|
        File.basename(f)
      end
    end

    def view_setups_for ctrl, action
      boot_app
      ctrl_instance = ctrl.new
      ctrl_instance.respond_to?(action.to_sym) || fail('"%s" route does not exists' % action)
      
      action_name, request_method = deRESTify_action(action)
      ctrl_instance.action_setup  = ctrl.action_setup[action_name][request_method]
      ctrl_instance.call_setups!
      [
        File.join(ctrl_instance.view_path?, ctrl_instance.view_prefix?),
        ctrl_instance.engine_ext?
      ]
    end

    def app_config
      pv, $VERBOSE = $VERBOSE, nil
      load dst_path.config_rb
      Cfg
    ensure
      $VERBOSE = pv
    end

  end
end
