if url = Cfg.db[:url]
  DataMapper.setup(:default, url)
elsif Cfg.db[:type] && Cfg.db[:name]
  if Cfg.db[:type] =~ /sqlite/i
    url = Cfg.db[:name] =~ /\A\// ? Cfg.db[:name] : Cfg.root_path(Cfg.db[:name])
  else
    url = '%s:%s@%s/%s' % Cfg.db.values_at(:user, :pass, :host, :name)
  end
  DataMapper.setup(:default, '%s://%s' % [Cfg.db[:type], url])
end
