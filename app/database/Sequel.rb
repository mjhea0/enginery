
if Cfg.db[:type] && Cfg.db[:name]
  if Cfg.db[:type].to_s =~ /sqlite/i
    DB = Sequel.sqlite Cfg.root_path(Cfg.db[:name])
  else
    DB = Sequel.connect "%s://%s:%s@%s/%s" % Cfg.db.values_at(:type, :user, :pass, :host, :name)
  end
end
