-- Creating the database

CREATE DATABASE IF NOT EXISTS nyc_crashes;
USE nyc_crashes;
DROP TABLE IF EXISTS crashes, outcomes;
SET GLOBAL local_infile = 1;

-- Creating the tables

CREATE TABLE crashes (
	collision_id        INT PRIMARY KEY,   -- one row per crash; also makes joins fast
    crash_date          DATE,
    crash_time          VARCHAR(10),
    borough             VARCHAR(50),
    contributing_factor VARCHAR(100),
    hour_of_day         INT,
    weekday             VARCHAR(20),
    time_period         VARCHAR(50)
);

CREATE TABLE outcomes (
	collision_id         INT PRIMARY KEY,
    persons_injured      INT,
    persons_killed       INT,
    pedestrians_injured  INT,
    pedestrians_killed   INT,
    cyclists_injured     INT,
    cyclists_killed      INT,
    motorists_injured    INT,
    motorists_killed     INT,
    injured              INT      -- 1 if anyone was injured, 0 if not
);

-- Loading the csv file

LOAD DATA LOCAL INFILE '/Users/hershoza/Downloads/CarCrashesAnalysis.csv'
INTO TABLE crashes
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(collision_id, crash_date, crash_time, borough,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip,
 contributing_factor, hour_of_day, weekday, time_period, @skip);

LOAD DATA LOCAL INFILE '/Users/hershoza/Downloads/CarCrashesAnalysis.csv'
INTO TABLE outcomes
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(collision_id, @skip, @skip, @skip,
 persons_injured, persons_killed, pedestrians_injured, pedestrians_killed,
 cyclists_injured, cyclists_killed, motorists_injured, motorists_killed,
 @skip, @skip, @skip, @skip, injured);
 
 -- Showing the csv 
 
 SELECT COUNT(*) AS total_crashes FROM crashes;
 SELECT COUNT(*) AS total_outcomes FROM outcomes;
 SELECT * FROM crashes;
 SELECT * FROM outcomes;
 
 -- Overall join
 
 SELECT * FROM crashes c
 JOIN outcomes o
 ON c.collision_id = o.collision_id;
 
 -- Sample queries
 
 SELECT c.borough,
		SUM(o.pedestrians_injured) AS pedestrians_injured,
		SUM(o.cyclists_injured)    AS cyclists_injured,
        SUM(o.motorists_injured)   AS motorists_injured,
        SUM(o.pedestrians_killed)  AS pedestrians_killed,
        SUM(o.cyclists_killed)     AS cyclists_killed,
        SUM(o.motorists_killed)    AS motorists_killed
 FROM crashes c
 INNER JOIN outcomes o ON c.collision_id = o.collision_id
 WHERE c.borough != ''
 GROUP BY c.borough
 ORDER BY pedestrians_injured DESC;
 
 SELECT c.time_period,
		COUNT(*) AS alcohol_crashes,
        SUM(o.persons_injured) AS people_injured,
        SUM(o.persons_killed) AS people_killed
 FROM crashes c
 INNER JOIN outcomes o ON c.collision_id = o.collision_id
 WHERE c.contributing_factor = 'Alcohol Involvement'
 GROUP BY c.time_period
 ORDER BY alcohol_crashes DESC;
 
 SELECT c.contributing_factor,
       COUNT(*) AS crashes,
       ROUND(100 * AVG(o.injured), 1) AS injury_rate_pct,
       SUM(o.persons_killed) AS people_killed
 FROM crashes c
 INNER JOIN outcomes o ON c.collision_id = o.collision_id
 WHERE c.contributing_factor NOT IN ('Unspecified', '')
 GROUP BY c.contributing_factor
 HAVING COUNT(*) >= 100
 ORDER BY injury_rate_pct DESC
 LIMIT 10;
        
 -- When do crashes happen?
 
 SELECT c.time_period,
		COUNT(*) AS crashes,
        ROUND(100 * AVG(o.injured), 1) AS injury_rate_pct,
        ROUND(1000 * AVG(o.persons_killed > 0), 2) AS deaths_per_1000_crashes
 FROM crashes c
 INNER JOIN outcomes o ON c.collision_id = o.collision_id
 GROUP BY c.time_period
 ORDER BY MIN(c.hour_of_day);
 
 -- Where do crashes happen?
 
 SELECT c.borough,
		COUNT(*) AS all_crashes,
        COUNT(o.collision_id) AS injury_crashes,
        ROUND(100 * COUNT(o.collision_id) / COUNT(*), 1) AS injury_rate_pct
 FROM crashes c
 LEFT JOIN outcomes o ON c.collision_id = o.collision_id AND o.injured = 1
 WHERE c.borough != ''
 GROUP BY c.borough
 ORDER BY all_crashes DESC;
 
 -- Why do crashes happens?
 
 SELECT c.contributing_factor,
		COUNT(*) AS all_crashes,
        COUNT(o.collision_id) AS injury_crashes,
        ROUND(100 * COUNT(o.collision_id) / COUNT(*), 1) AS injury_rate_pct
 FROM outcomes o
 RIGHT JOIN crashes c ON c.collision_id = o.collision_id AND o.injured = 1
 WHERE c.contributing_factor NOT IN ('Unspecified', '')
 GROUP BY c.contributing_factor
 ORDER BY all_crashes DESC
 LIMIT 10;
 
 