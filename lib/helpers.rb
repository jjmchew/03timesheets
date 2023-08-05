def get_projects_list(userid)
  projects = @storage.get_projects(userid)
  session[:user][:valid_projects] = projects
  projects
end

# ----------- errors-related --------------

def error_msg(status_code, msg)
  status status_code
  session[:error] = msg
end

def project_name_errors(project_name)
  errors = []
  errors << 'Please enter a project description' if project_name.empty?
  valid_projects = session[:user][:valid_projects]
  if valid_projects.any? { |obj| obj[:project_name] == project_name }
    errors << 'Please enter a unique name'
  end
  errors
end

def username_errors
  errors = []
  userhash = user_hash(params[:username])
  unless @storage.get_id_from_user(userhash).nil?
    errors << 'Username already taken - please choose another username'
  end
  errors << 'Please enter a username' if params[:username].strip == ''
  errors
end

def pw_errors(pw)
  errors = []
  errors << 'Please enter a (non-blank) password' if pw.strip.empty?
  unless (3..15).cover?(pw.size)
    errors << 'Please enter a password between 3 and 15 characters'
  end
  errors
end

# ----------- csv-related --------------

def csv_out_all(str=false)
  out = [['date', 'desc', 'start', 'end']]
  out += @storage.get_csv_all(user_id).map do |obj|
    [dfrmt(obj[:date]),
     obj[:project_name],
     tfrmt(obj[:start_time]),
     tfrmt(obj[:end_time])]
  end
  return out.map { |ary| ary.join(',') }.join("\n") if str
  out
end

def csv_out_specific(project_id, str=false)
  out = [['date', 'desc', 'start', 'end']]
  out += @storage.get_csv_specific(user_id, project_id).map do |obj|
    [dfrmt(obj[:date]),
     obj[:project_name],
     tfrmt(obj[:start_time]),
     tfrmt(obj[:end_time])]
  end
  return out.map { |ary| ary.join(',') }.join("\n") if str
  out
end

def dfrmt(date)
  date.strftime('%d-%b-%y')
end

def tfrmt(time)
  time.strftime('%H:%M:%S')
end

# ----------- user-related --------------

def require_valid_user
  cache_control :no_store
  return if valid_user?

  error_msg(302, 'You must be logged in to access this page')
  session[:redirect_to] = request_url
  redirect '/login'
end

def require_valid_project_id
  return if valid_project_id?
  error_msg(302, "I'm sorry, you can't view that page")
  redirect '/goals'
end

def valid_project_id?
  return false unless valid_id_param?(params[:project_id])
  valid_ids = session[:user][:valid_projects]
  valid_ids.any? { |obj| obj[:id] == params[:project_id].to_i }
end

def valid_id_param?(str)
  str.to_i.to_s == str
end

def valid_user?
  !session[:user].nil?
end

# -------- for users database -----------

require 'bcrypt'
require 'digest'

def user_hash(username)
  Digest::MD5.hexdigest(username)
end

def pw_hash(password)
  BCrypt::Password.create(password)
end

def get_db_id(username, pw="")
  user_hash = Digest::MD5.hexdigest(username)
  db = @storage.get_pw_from_user(user_hash)

  return false if db.nil?
  return db[:id] if BCrypt::Password.new(db[:pw]) == pw
end
