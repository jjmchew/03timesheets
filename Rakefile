desc 'run tests'
task :test do
  test_files.each { |file| sh "ruby ./test/#{file}" }
end

desc 'run rubocop on key files'
task :rubocop_lib do
  sh 'rubocop app.rb'
  sh 'rubocop ./lib/db_persistence.rb'
  sh 'rubocop ./lib/helpers.rb'
  sh 'rubocop ./lib/ts_tally.rb'
end

desc 'run rubocop on test files'
task :rubocop_test do
  test_files.each { |file| sh "rubocop ./test/#{file}" }
end

desc 'run rubocop_lib, rubocop_test'
task :rubocop => [:rubocop_lib, :rubocop_test]

desc 'setup initial db using psql'
# change 'projdb' to fit localonly.yml :dbname
task :db do
  sh 'psql < setup_db.sql'
  sh 'psql -d jjmchewa_timesheets < schema.sql'
  sh 'psql -d jjmchewa_timesheets < sample_data.sql'
end

desc 'run program file (config.ru)'
task :run do
  sh 'bundle exec rackup -p 8889 config.ru'
end

desc 'run tasks: rubocop, test'
task :_check => [:rubocop, :test]

desc 'run tasks: db, :run'
task :_firststart => [:db, :run]

task :default => :test

# ================

def test_files
  root = File.expand_path('..', __FILE__)
  Dir.glob("#{root}/test/*.rb").map { |full_path| File.basename(full_path) }
end
