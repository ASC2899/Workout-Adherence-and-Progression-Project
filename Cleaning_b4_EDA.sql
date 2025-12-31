-- I used Copilot to generate this query.

USE workout_project;
-- Step 1: Check if d_date table already exits and drop it.
DROP TABLE IF EXISTS d_date;

-- Step 2: Creating d_date table.
CREATE TABLE d_date (
    date DATE,
    year INT,
    month_no INT,
    day INT,
    day_name VARCHAR(10),
    day_name_short VARCHAR(3),
    month_name VARCHAR(10),
    month_name_short VARCHAR(3),
    quarter INT,
    quarter_name VARCHAR(2),
    week_of_year INT,
    date_key INT PRIMARY KEY
);

-- Step 3: Define the stored procedure to populate the table.
DROP PROCEDURE IF EXISTS populate_calendar;

DELIMITER $$

CREATE PROCEDURE populate_calendar()
BEGIN
    DECLARE _current_date DATE DEFAULT '2023-07-07';
    DECLARE end_date DATE DEFAULT '2025-05-09'; -- Because First and last log of workouts are on 2023-07-07 and 2025-05-09 respectively.

    WHILE _current_date <= end_date DO
        INSERT INTO d_date (
            date,
            year,
            month_no,
            day,
            day_name,
            day_name_short,
            month_name,
            month_name_short,
            quarter,
            quarter_name,
            week_of_year,
            date_key
        )
        VALUES (
            _current_date,
            YEAR(_current_date),
            MONTH(_current_date),
            DAY(_current_date),
            DAYNAME(_current_date),
            LEFT(DAYNAME(_current_date), 3),
            MONTHNAME(_current_date),
            LEFT(MONTHNAME(_current_date), 3),
            QUARTER(_current_date),
            CONCAT('Q', QUARTER(_current_date)),
            WEEK(_current_date, 1),
            DATE_FORMAT(_current_date, '%Y%m%d')
        );

        SET _current_date = DATE_ADD(_current_date, INTERVAL 1 DAY);
    END WHILE;
END$$

DELIMITER ;

-- Step 4: Execute the procedure.
CALL populate_calendar;

-- Step 5: Validate d_date table.
SELECT * FROM d_date WHERE date_key = 20230707 LIMIT 1;


-- ______________________________Cleaning other tables______________________________ --

-- Changing data types of columns in d_workouts.ALTER
ALTER TABLE d_workouts 
    MODIFY date_key INT NOT NULL,
    MODIFY weight DECIMAL(10,2),
    MODIFY reps DECIMAL(10,2),
    MODIFY exercise_key INT;
    
-- Making exercise_key as primary key and changing muscle_part_key to int.
ALTER TABLE d_exercie
	MODIFY exercise_key INT NOT NULL,
	ADD PRIMARY KEY (exercise_key),
    MODIFY muscle_part_key INT NOT NULL;

-- Making muscle_part_key as primary key and changing muscle_group_key to int.
ALTER TABLE d_muscle_part
	MODIFY muscle_part_key INT NOT NULL,
	ADD PRIMARY KEY (muscle_part_key),
    MODIFY muscle_group_key INT NOT NULL;

-- Making muscle_group_key as primary key.
ALTER TABLE d_muscle_group
	MODIFY muscle_group_key INT NOT NULL,
	ADD PRIMARY KEY (muscle_group_key);