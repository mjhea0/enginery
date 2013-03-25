if Cfg.db[:type] && Cfg.db[:name]
  if Cfg.db[:type] =~ /sqlite/i
    DB = Sequel.sqlite Cfg.db[:name] =~ /\A\// ? Cfg.db[:name] : Cfg.root_path(Cfg.db[:name])
  else
    DB = Sequel.connect "%s://%s:%s@%s/%s" % Cfg.db.values_at(:type, :user, :pass, :host, :name)
  end
end
