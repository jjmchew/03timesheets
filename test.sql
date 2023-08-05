-- SELECT projects.id,
--     project_name,
--     COUNT(*) FILTER (WHERE "end_time" IS NULL AND "start_time" IS NOT NULL) AS timer_on,
--     created_on
-- FROM projects
-- FULL JOIN timers ON timers.project_id = projects.id
-- WHERE projects.user_id = 1
-- GROUP BY projects.id
-- ORDER BY projects.created_on, projects.id

-- ------------------------------------

-- SELECT projects.user_id,
--        timers.project_id,
--        date(start_time),
--        projects.project_name,
--        timers.start_time,
--        timers.end_time,
--        exported
-- FROM timers
-- JOIN projects
-- ON project_id = projects.id
-- WHERE projects.user_id = 2
-- ORDER BY timers.start_time, timers.id

-- ------------------------------------

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
WHERE projects.user_id = 2 AND timers.project_id = 3
ORDER BY timers.start_time, timers.id