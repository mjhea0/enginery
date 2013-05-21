connection = if url = Cfg.db[:url]
  Sequel.connect(url)
elsif Cfg.db[:type] && Cfg.db[:name]
  if Cfg.db[:type] =~ /sqlite/i
    Sequel.sqlite(Cfg.db[:name] =~ /\A\// ? Cfg.db[:name] : Cfg.root_path(Cfg.db[:name]))
  else
    Sequel.connect("%s://%s:%s@%s/%s" % Cfg.db.values_at(:type, :user, :pass, :host, :name))
  end
end
Sequel::Model.db = connection if connection
