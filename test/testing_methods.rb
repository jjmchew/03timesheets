module TestingMethods
  def setup_testdb
    sql = File.open('./schema.sql', &:read)
    sql2 = File.open('./test/test_data.sql', &:read)
    @db.exec(sql)
    @db.exec(sql2)
  end

  def setup
    db = PG.connect(dbname: 'postgres')
    db.exec('CREATE DATABASE testdb;')
    db.close
    @db = PG.connect(dbname: 'testdb')
    setup_testdb
    @db.close
  end

  def teardown
    db = PG.connect(dbname: 'postgres')
    db.exec('DROP DATABASE testdb;')
    db.close
  end

  def session
    last_request.env['rack.session']
  end

  def path_only(location)
    location.gsub('http://example.org', '')
  end
end
