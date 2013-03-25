if Cfg.db[:type] && Cfg.db[:name]
  url = '%s:%s@%s/%s' % Cfg.db.values_at(:user, :pass, :host, :name)
  if Cfg.db[:type] =~ /sqlite/i
    url = Cfg.db[:name] =~ /\A\// ? Cfg.db[:name] : Cfg.root_path(Cfg.db[:name])
  end
  ActiveRecord::Base.establish_connection '%s://%s' % [Cfg.db[:type], url]
end
