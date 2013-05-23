module Enginery
  class Registry
    include Helpers

    def initialize root
      @dst_root = root.freeze
    end

    def controllers
      boot_app
      app_controllers.inject({}) do |f,c|
        path   = EUtils.class_to_route(c.name)
        routes = routes_by_controller(c.name).inject({}) do |f,r|
          f.merge r => {
            name: r,
            route: c[r.to_sym],
            file: unrootify(dst_path(:controllers, path, r + ROUTE_SUFFIX)),
            views: Dir[dst_path(:views, path, r + '.*')].map {|f| unrootify(f)},
            specs: Dir[dst_path(:specs, path, r + SPEC_SUFFIX)].map {|f| unrootify(f)}
          }
        end
        data = {
          name: c.name,
          path: path,
          file: unrootify(dst_path(:controllers, path + CONTROLLER_SUFFIX)),
          dom_id: c.name.gsub(/\W/m, ''),
          routes: routes,
          specs:  routes.inject(0) {|s,(n,r)| s += r[:specs].size}
        }
        helper_file = dst_path(:helpers, path + HELPER_SUFFIX)
        File.exists?(helper_file) && data[:helper_file] = unrootify(helper_file)
        f.merge c.name => data
      end.to_yaml
    end

    def models
      app_models.inject({}) do |f,c|
        path = EUtils.class_to_route(c.name)
        migrations = migrations_by_model(c.name).inject({}) do |f,m| 
          step, time, name = m.scan(Migrator::NAME_REGEXP).flatten
          file = dst_path(:migrations, path, m)
          f.merge ('%s. %s' % [step, name.to_s.gsub('-', ' ')]) => {
            step: step,
            name: name,
            time: time,
            file: unrootify(file),
            path: file.sub(dst_path.migrations, '')
          }
        end
        f.merge c.name => {
          name: c.name,
          path: path,
          file: unrootify(dst_path(:models, path + MODEL_SUFFIX)),
          rear_file: unrootify(dst_path(:rear_controllers, path + ADMIN_SUFFIX)),
          dom_id: c.name.gsub(/\W/m, ''),
          migrations: migrations
        }
      end.to_yaml
    end
  end
end
