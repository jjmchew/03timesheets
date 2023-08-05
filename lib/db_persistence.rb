require 'pg'

class DatabasePersistence
  # rubocop:disable Metrics/MethodLength, Layout/LineLength
  def initialize(logger, mode)
    @logger = logger
    @db = case mode
          when 'development'
            PG.connect(dbname: CONFIG[:dbname])
          when 'test'
            PG.connect(dbname: 'testdb')
          else
            PG.connect(dbname: CONFIG[:dbname],
                       user: CONFIG[:user],
                       password: CONFIG[:password])
          end
  end

  def query(sql, *params)
    @logger.info "#{sql} : #{params}"
    @db.exec_params(sql, params)
  end

  def add_project(user_id, new_project_name)
    sql = 'INSERT INTO projects (user_id, project_name) VALUES ($1, $2)'
    query(sql, user_id, new_project_name)
  end

  def hide_project(user_id, project_id)
    sql = 'UPDATE projects SET display=false WHERE user_id=$1 AND id=$2;'
    query(sql, user_id, project_id)
  end

  # -----------

  def get_projects(user_id)
    sql = <<~SQL
      SELECT projects.id,
          project_name,
          COUNT(*) FILTER (WHERE "end_time" IS NULL AND "start_time" IS NOT NULL) AS timer_on,
          created_on
      FROM projects
      FULL JOIN timers ON timers.project_id = projects.id
      WHERE projects.user_id = $1 AND projects.display = true
      GROUP BY projects.id
      ORDER BY projects.created_on, projects.id
    SQL
    result = query(sql, user_id)
    result.map do |tuple|
      { id: tuple['id'].to_i,
        project_name: tuple['project_name'],
        timer_on: tuple['timer_on'].to_i,
        created_on: DateTime.strptime(tuple['created_on'], '%Y-%m-%d %H:%M:%S.%N') }
    end
  end

  def get_csv_out(user_id)
    sql = <<~SQL
      SELECT projects.user_id,
             timers.project_id,
             projects.project_name,
             date(start_time),
             timers.start_time,
             timers.end_time,
             exported
      FROM timers
      JOIN projects
      ON project_id = projects.id
      WHERE projects.user_id = $1
      ORDER BY timers.start_time, timers.id
    SQL
    result = query(sql, user_id)
    result.map do |tuple|
      { project_id: tuple['project_id'].to_i,
        date: Date.strptime(tuple['date'], '%Y-%m-%d'),
        project_name: tuple['project_name'],
        start_time: Time.strptime(tuple['start_time'], '%Y-%m-%d %H:%M:%S.%N'),
        end_time: Time.strptime(tuple['end_time'], '%Y-%m-%d %H:%M:%S.%N') }
    end
  end
  # rubocop:enable Metrics/MethodLength, Layout/LineLength

  # ----------- timers

  def start_timer(project_id)
    sql = 'INSERT INTO timers (project_id) VALUES ($1);'
    query(sql, project_id)
  end

  def stop_timer(project_id)
    sql = <<~SQL
      UPDATE timers SET end_time=CURRENT_TIMESTAMP WHERE project_id=$1 AND end_time IS NULL;
    SQL
    query(sql, project_id)
  end

  # ----------- user-account related

  def get_pw_from_user(user_hash)
    sql = 'SELECT id, pw FROM users WHERE username=$1;'
    result = query(sql, user_hash)

    return nil if result.first.nil?
    { id: result.first['id'].to_i, pw: result.first['pw'] }
  end

  def get_id_from_user(user_hash)
    result = query('SELECT id FROM users WHERE username=$1;', user_hash)
    return nil if result.first.nil?
    { id: result.first['id'].to_i }
  end

  def create_new_user(user_hash, pw_hash)
    sql = 'INSERT INTO users (username, pw) VALUES ($1, $2);'
    query(sql, user_hash, pw_hash)
  end

  # -----------

  def close_db
    @db.close
  end
end
