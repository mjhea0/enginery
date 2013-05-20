+ 0.0.8 [HEAD]
  - Ability to delete any generated unit.
  - Default layout for `ERB`, `ERubis`, `Haml` and `Slim` engines.
  - Automatically generate and include helpers.
    - Migrator - DataMapper - auto-update model file when performing migrations.
  - Migrator - keep tracks in database so it is usable on environments with readonly filesystem - [52360b5](https://github.com/espresso/enginery/commit/52360b5)
  - Migrator - when available, use `ENV['DATABASE_URL']` instead of config/database.yml - [bbb41618](https://github.com/espresso/enginery/commit/bbb41618)
  - Migrator - run all outstanding migrations when no steps provided [93bef48](https://github.com/espresso/enginery/commit/93bef48)
  - Verbosify auto_migrate/upgrade rake tasks on DataMapper [782e76e](https://github.com/espresso/enginery/commit/782e76e)
  - 
<hr>
