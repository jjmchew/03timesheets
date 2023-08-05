require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'yaml'
require 'date'
require 'pry' if development? || test?

require_relative './lib/db_persistence'
require_relative './lib/helpers'
require_relative './lib/ts_tally'

CONFIG = YAML.load(File.read('localonly.yml'))

BASE_URL = ENV['RACK_ENV'] == 'production' ? '/timesheets' : ''

configure do
  enable :sessions
  set :session_secret, CONFIG[:session_secret] # SecureRandom.hex(32)
  set :erb, escape_html: true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload './lib/db_persistence.rb', './lib/helpers.rb', './lib/ts_tally'
end

helpers do
  def user
    return nil unless valid_user?
    session[:user][:username]
  end

  def user_id
    return nil unless valid_user?
    session[:user][:id]
  end
end

before do
  @storage = DatabasePersistence.new(logger, ENV['RACK_ENV'])
end

after do
  @storage.close_db
end

get '/' do
  redirect url('/projects') if valid_user?
  erb :help
end

# display login page
get '/login' do
  erb :login
end

# login user
post '/login' do
  username = params[:username]
  id = get_db_id(username, params[:pw])
  if id
    session[:user] = {
      username: username,
      id: id
    }
    get_projects_list(id)
    session[:message] = "Login successful"
    redirect url('/projects')
  else
    error_msg(400, 'Username / password not found. Please try again.')
    erb :login
  end
end

# logout user
post '/logout' do
  session[:user] = nil
  session[:message] = 'Successfully logged out'
  redirect url('/')
end

# display projects page
get '/projects' do
  require_valid_user

  @projects = get_projects_list(user_id)
  erb :projects
end

# stop displaying project (timer button)
post '/projects/:project_id/hide' do
  require_valid_user
  require_valid_project_id

  project_id = params[:project_id].to_i
  @storage.hide_project(user_id, project_id)
  session[:message] = 'Project hidden'
  redirect url('/projects')
end

# add a 'start_time' entry
post '/projects/:project_id/start' do
  require_valid_user
  require_valid_project_id

  project_id = params[:project_id].to_i
  @storage.start_timer(project_id)
  session[:message] = 'Timer started'
  redirect url('/projects')
end

# add a 'stop_time' entry
post '/projects/:project_id/stop' do
  require_valid_user
  require_valid_project_id

  project_id = params[:project_id].to_i
  @storage.stop_timer(project_id)
  session[:message] = 'Timer stopped'
  redirect url('/projects')
end

# display new project form
get '/projects/new' do
  require_valid_user
  erb :new_project
end

# add new project
post '/projects/new' do
  require_valid_user
  new_project_name = params[:new_project_name].strip

  errors = project_name_errors(new_project_name)
  if errors.empty?
    @storage.add_project(user_id, new_project_name)
    session[:message] = 'New project added'
    redirect url('/projects')
  else
    msg = errors.join(', ')
    error_msg(400, msg)
    erb :new_project
  end
end

# display csv output on-screen
get '/csv/all' do
  require_valid_user
  headers['Content-Type'] = 'text/plain'
  csv_out_all(true)
end

# display daily / weekly tallies on-screen
get '/tally' do
  require_valid_user
  headers['Content-Type'] = 'text/plain'
  TSTally.new(csv_out_all).display
end

# display create new account page
get '/users/new' do
  erb :new_user
end

# create new user
post '/users/new' do
  errors = username_errors
  errors += pw_errors(params[:pw])
  if errors.empty?
    user_hash = user_hash(params[:username])
    pw_hash = pw_hash(params[:pw])
    @storage.create_new_user(user_hash, pw_hash)
    session[:message] = 'New user successfully created.  Please login.'
    redirect url('/login')
  else
    error_msg(400, errors.join(', '))
    erb :new_user
  end
end

not_found do
  erb :not_found
end
