-- change 'projdb' to fit localonly.yml :dbname
\c postgres
DROP DATABASE IF EXISTS jjmchewa_timesheets;
CREATE DATABASE jjmchewa_timesheets;
\c jjmchewa_timesheets
