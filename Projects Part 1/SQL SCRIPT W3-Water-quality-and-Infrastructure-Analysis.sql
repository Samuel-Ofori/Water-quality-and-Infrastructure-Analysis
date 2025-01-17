-- Start by joining location to visits.
SELECT province_name, town_name,visit_count, v.location_id
FROM location AS l
JOIN visits AS v
ON l.location_id = v.location_id;

-- Now, we can join the water_source table on the key shared between water_source and visits.
SELECT province_name, town_name,visit_count, v.location_id, type_of_water_source,number_of_people_served
FROM location AS l
JOIN visits AS v
ON l.location_id = v.location_id
JOIN water_source AS ws
ON v.source_id = ws.source_id;

/* Note that there are rows where visit_count > 1. These were the sites our surveyors collected additional information for, but they happened at the
same source/location. For example, add this to your query: WHERE visits.location_id = 'AkHa00103' */
SELECT province_name, town_name,visit_count, v.location_id, type_of_water_source,number_of_people_served
FROM location AS l
JOIN visits AS v
ON l.location_id = v.location_id
JOIN water_source AS ws
ON v.source_id = ws.source_id
WHERE v.location_id =  'AkHa00103';

/* There you can see what I mean. For one location, there are multiple AkHa00103 records for the same location. If we aggregate, we will include
these rows, so our results will be incorrect. To fix this, we can just select rows where visits.visit_count = 1.*/
SELECT province_name, town_name,visit_count, v.location_id, type_of_water_source,number_of_people_served
FROM location AS l
JOIN visits AS v
ON l.location_id = v.location_id
JOIN water_source AS ws
ON v.source_id = ws.source_id
WHERE v.visit_count = 1;


/* Last one! Now we need to grab the results from the well_pollution table.
This one is a bit trickier. The well_pollution table contained only data for well. If we just use JOIN, we will do an inner join, so that only records
that are in well_pollution AND visits will be joined. We have to use a LEFT JOIN to join theresults from the well_pollution table for well
sources, and will be NULL for all of the rest. Play around with the different JOIN operations to make sure you understand why we used LEFT JOIN.*/
SELECT
water_source.type_of_water_source,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

/* So this table contains the data we need for this analysis. Now we want to analyse the data in the results set. We can either create a CTE, and then
query it, or in my case, I'll make it a VIEW so it is easier to share with you. I'll call it the combined_analysis_table.*/
CREATE VIEW combined_analysis_table AS
SELECT
water_source.type_of_water_source AS source_type,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served AS people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

/* We're building another pivot table! This time, we want to break down our data into provinces or towns and source types. If we understand where
the problems are, and what we need to improve at those locations, we can make an informed decision on where to send our repair teams.*/
WITH province_totals AS (   -- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name, -- These case statements create columns for each type of source.The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

/* province_totals is a CTE that calculates the sum of all the people surveyed grouped by province. If you replace the query above with this one:
SELECT*FROMprovince_totals*/
WITH province_totals AS (   -- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT * FROM province_totals;

/* Let's aggregate the data per town now. You might think this is simple, but one little town makes this hard. Recall that there are two towns in Maji
Ndogo called Harare. One is in Akatsi, and one is in Kilimani. Amina is another example. So when we just aggregate by town, SQL doesn't distinguish between the different Harare's, so it combines their results.
To get around that, we have to group by province first, then by town, so that the duplicate towns are distinct because they are in different towns*/
WITH town_totals AS (              -- This CTE calculates the population of each town.Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN                       -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY                 -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

/* Temporary tables in SQL are a nice way to store the results of a complex query. We run the query once, and the results are stored as a table. The
catch? If you close the database connection, it deletes the table, so you have to run it again each time you start working in MySQL. The benefit is
that we can use the table to do more calculations, without running the whole query each time.*/
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (              -- This CTE calculates the population of each town.Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN                       -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY                 -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- There are still many gems hidden in this table. For example, which town has the highest ratio of people who have taps, but have no running water?
SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *
100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access;

--  Let's call this table Project_progress.
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);

-- Let's take the various Improvements one by one, then combine them into one query at the end.To make this simpler, we can start with this query: Project_progress_query
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id;

-- , my thinking is to remove all of the data we don't need first, like records with visit_count > 1, and then do calculations.lets start with the WHERE section:
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
AND (results != 'Clean' 
OR type_of_water_source IN ('tap_in_home_broken', 'river')
OR (type_of_water_source = 'shared_tap' AND (time_in_queue >= 30))
);

/*Use some control flow logic to create Install UV filter or Install RO filter values in the Improvement column where the results of the pollution tests were Contaminated: Biological and Contaminated: Chemical respectively. Think about the data you'll need, and which table to find
it in. Use ELSE NULL for the final alternative.*/
SELECT 
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    results,
    CASE
        WHEN results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN results = 'Contaminated: Chemical' THEN 'Install RO filter'
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (type_of_water_source = 'shared_tap'
        AND (time_in_queue >= 30)));
        
-- Add Drill well to the Improvements column for all river sources.
SELECT 
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    results,
    CASE
        WHEN results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN type_of_water_source = 'river' THEN 'Drill Well'
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (type_of_water_source = 'shared_tap'
        AND (time_in_queue >= 30)));

-- shared tap
SELECT 
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    results,
    CASE
        WHEN results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN type_of_water_source = 'river' THEN 'Drill Well'
        WHEN type_of_water_source = 'shared_tap' AND (time_in_queue >= 30) 
        THEN CONCAT('Install ', FLOOR(time_in_queue/30), ' tap(s) nearby')
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (type_of_water_source = 'shared_tap'
        AND (time_in_queue >= 30)));        

-- You can also used NESTED IF and CASE statement
SELECT 
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    results,
    CASE
        WHEN results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN type_of_water_source = 'river' THEN 'Drill Well'
        WHEN type_of_water_source = 'shared_tap' AND (time_in_queue >= 30) 
        THEN IF (FLOOR(time_in_queue/30)= 1,'Install 1 tap nearby',
        CONCAT('Install ', FLOOR(time_in_queue/30), ' taps nearby'))
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (type_of_water_source = 'shared_tap'
        AND (time_in_queue >= 30)));

-- Add a case statement to our query updating broken taps to Diagnose local infrastructure.
SELECT 
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    results,
    CASE
        WHEN results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN type_of_water_source = 'river' THEN 'Drill Well'
        WHEN type_of_water_source = 'shared_tap' AND (time_in_queue >= 30) 
        THEN IF (FLOOR(time_in_queue/30)= 1,'Install 1 tap nearby',
        CONCAT('Install ', FLOOR(time_in_queue/30), ' taps nearby'))
        WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (type_of_water_source = 'shared_tap'
        AND (time_in_queue >= 30)));
        
/* Now that we have the data we want to provide to engineers, populate the Project_progress table with the results of our query.
HINT: Make sure the columns in the query line up with the columns in Project_progress. If you make any mistakes, just use DROP TABLE
project_progress, and run your query again.*/
CREATE TEMPORARY TABLE Project_report AS
SELECT 
    location.address AS Address,
    location.town_name AS Town,
    location.province_name AS Province,
    water_source.source_id,
    water_source.type_of_water_source AS Source_type,
    results,
    CASE
        WHEN results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN type_of_water_source = 'river' THEN 'Drill Well'
        WHEN type_of_water_source = 'shared_tap' AND (time_in_queue >= 30) 
        THEN IF (FLOOR(time_in_queue/30)= 1,'Install 1 tap nearby',
        CONCAT('Install ', FLOOR(time_in_queue/30), ' taps nearby'))
        WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (type_of_water_source = 'shared_tap'
        AND (time_in_queue >= 30)));
        
-- Insert into project progress  
INSERT INTO project_progress(source_id, Address, Town, Province, Source_type, Improvement)
SELECT source_id, Address, Town, Province, Source_type, Improvement
FROM project_report;