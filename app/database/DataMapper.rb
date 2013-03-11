
if Cfg.db[:type] && Cfg.db[:name]
  values, name = Cfg.db.values_at(:type, :user, :pass, :host), Cfg.db[:name]
  (Cfg.db[:type].to_s =~ /sqlite/i) && (name = Cfg.root_path(name))
  connection_string = "%s://%s:%s@%s/#{name}" % values
  DataMapper.setup :default, connection_string
end
