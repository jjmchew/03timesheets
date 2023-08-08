CREATE TABLE users (
  id serial PRIMARY KEY,
  username char(32) NOT NULL UNIQUE,
  pw char(60) NOT NULL
);

CREATE TABLE projects (
  id serial PRIMARY KEY,
  user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  project_name text NOT NULL,
  created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  display boolean DEFAULT true
);

ALTER TABLE projects ADD UNIQUE(user_id, project_name);

CREATE TABLE timers (
  id serial PRIMARY KEY,
  project_id integer REFERENCES projects(id) ON DELETE CASCADE,
  start_time timestamp with time zone NOT NULL UNIQUE DEFAULT CURRENT_TIMESTAMP,
  end_time timestamp with time zone,
  exported boolean DEFAULT false
);
