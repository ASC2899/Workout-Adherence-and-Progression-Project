USE workout_project;


-- 1. What are the total calendar days in scope, 
--    the total workout days logged and my adherence % 
--    excluding Sundays in all three metrics?
SELECT (SELECT COUNT(*) 
		FROM d_date WHERE day_name <> 'Sunday') AS total_calendar_days
        ,
	   (SELECT COUNT(DISTINCT date_key) 
        FROM d_workouts) AS total_workout_days
        ,
       ROUND(
	       100 * (SELECT COUNT(DISTINCT date_key) FROM d_workouts) / 
			(SELECT COUNT(*) FROM d_date WHERE day_name <> 'Sunday'), 2
             ) AS adherence_pct;

-- 2. Total skipped days excluding Sundays?
SELECT COUNT(*) AS total_skipped_days
FROM d_date d
LEFT JOIN (SELECT DISTINCT date_key FROM d_workouts) w 
	ON d.date_key = w.date_key
WHERE w.date_key IS NULL AND day_name <> 'Sunday';  -- 259 (approx -45 days from accident recovery 
--                                                          so total skipped days should be near 214 but anyways)

-- 3. Which weekdays I workout the most?
SELECT d.day_name, COUNT(*) AS workouts
FROM d_workouts w
JOIN d_date d ON w.date_key = d.date_key
GROUP BY d.day_name
ORDER BY workouts DESC;

-- 4. Which weekdays I skipped workout the most?
SELECT d.day_name, COUNT(*) AS skipped_days
FROM d_date d
LEFT JOIN (SELECT DISTINCT date_key FROM d_workouts) w ON d.date_key = w.date_key
WHERE w.date_key IS NULL AND day_name <> 'Sunday'
GROUP BY d.day_name
ORDER BY skipped_days DESC;

-- 5. What's the total volume % within each muscle part among all muscle groups?                                  **
SELECT 
    mg.muscle_group,
    mp.muscle_part,
    ROUND(SUM(w.reps * w.weight), 2) AS total_volume,
    ROUND(
        100 * SUM(w.reps * w.weight) /
        SUM(SUM(w.reps * w.weight)) OVER (PARTITION BY mg.muscle_group),
        2
    ) AS pct_volume_within_group
FROM d_workouts w
JOIN d_exercie e ON w.exercise_key = e.exercise_key
JOIN d_muscle_part mp ON e.muscle_part_key = mp.muscle_part_key
JOIN d_muscle_group mg ON mp.muscle_group_key = mg.muscle_group_key
GROUP BY mg.muscle_group, mp.muscle_part
ORDER BY mg.muscle_group, pct_volume_within_group DESC;

-- 6. What's my PR for each exerccise per muscle part per muscle group?
WITH pr_candidates AS (
    SELECT 
        mg.muscle_group,
        mp.muscle_part,
        e.exercise,
        w.weight,
        w.reps,
        ROW_NUMBER() OVER (
            PARTITION BY mg.muscle_group, e.exercise
            ORDER BY w.weight DESC, w.reps DESC
        ) AS rn
    FROM d_workouts w
    JOIN d_exercie e ON w.exercise_key = e.exercise_key
    JOIN d_muscle_part mp ON e.muscle_part_key = mp.muscle_part_key
    JOIN d_muscle_group mg ON mp.muscle_group_key = mg.muscle_group_key
    WHERE w.reps >= 8
)
SELECT 
    muscle_group,
    muscle_part,
    exercise,
    weight,
    reps
FROM pr_candidates
WHERE rn = 1
ORDER BY muscle_group, muscle_part;

-- 7. Am I too scattered or nicely focused Couple of exercises per muscle group?
SELECT 
    mg.muscle_group,
    COUNT(DISTINCT e.exercise) AS unique_exercises
FROM d_workouts w
JOIN d_exercie e ON w.exercise_key = e.exercise_key
JOIN d_muscle_part mp ON e.muscle_part_key = mp.muscle_part_key
JOIN d_muscle_group mg ON mp.muscle_group_key = mg.muscle_group_key
GROUP BY mg.muscle_group
ORDER BY unique_exercises DESC;

-- 8. What are the total sets performed per exercise per muscle group?
SELECT
	mg.muscle_group,
    mp.muscle_part,
    e.exercise,
    COUNT(*) AS sets
FROM d_workouts w
JOIN d_exercie e ON w.exercise_key = e.exercise_key
JOIN d_muscle_part mp ON e.muscle_part_key = mp.muscle_part_key
JOIN d_muscle_group mg ON mp.muscle_group_key = mg.muscle_group_key
GROUP BY mg.muscle_group, mp.muscle_part, e.exercise
ORDER BY mg.muscle_group, mp.muscle_part, sets DESC;

