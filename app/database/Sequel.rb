unless url = Cfg.db[:url]
  if (type = Cfg.db[:type]) && (name = Cfg.db[:name])
    if type =~ /sqlite/i
      url = [(name =~ /\A\// ? name : Cfg.root_path(name)), :sqlite]
    else
      url = '%s://%s:%s@%s/%s' % Cfg.db.values_at(:type, :user, :pass, :host, :name)
    end
  end
end
url, connection_method = url
Sequel::Model.db = Sequel.send(connection_method || :connect, url) if url
