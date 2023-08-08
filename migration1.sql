-- migrates from schema to schema1:
ALTER TABLE projects
  ALTER COLUMN created_on
  TYPE timestamp with time zone;

ALTER TABLE timers
  ALTER COLUMN start_time
  TYPE timestamp with time zone;

ALTER TABLE timers
  ALTER COLUMN end_time
  TYPE timestamp with time zone;