USE md_water_services;

-- cleaning our data

SELECT 
    *
FROM
    employee;
    
SELECT 
    CONCAT(LOWER(REPLACE(employee_name, " ", ".")), "@ndogowater.gov") AS email
FROM
    employee;
    
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, " ", ".")), "@ndogowater.gov");

SET SQL_SAFE_UPDATES = 0;

SELECT 
    LENGTH(phone_number)
FROM
    employee;
    
SELECT 
    LENGTH(TRIM(phone_number))
FROM
    employee;
    
UPDATE employee
SET phone_number = TRIM(phone_number);

SELECT 
    *
FROM
    employee;
    
-- Honouring workers 

SELECT 
   town_name, COUNT(employee_name) AS num_of_employees
FROM
    employee
GROUP BY town_name;

SELECT 
    *
FROM
    visits;
    
SELECT 
  assigned_employee_id, COUNT(visit_count) AS number_visits
FROM
    visits
GROUP BY assigned_employee_id
ORDER BY number_visits DESC
LIMIT 3;

SELECT 
    *
FROM
    employee
WHERE
	assigned_employee_id IN (1, 30, 34);
    
-- Analyzing location

SELECT 
    province_name, town_name, location_type
FROM
    location;
    
SELECT 
    town_name, COUNT(town_name) AS records_per_town
FROM
    location
GROUP BY town_name
ORDER BY records_per_town DESC;

SELECT 
    province_name, COUNT(province_name) AS records_per_province
FROM
    location
GROUP BY province_name
ORDER BY records_per_province DESC;

SELECT 
    province_name,
    town_name,
    COUNT(province_name) AS records_per_town
FROM
    location
GROUP BY province_name, town_name
ORDER BY province_name, records_per_town DESC;

SELECT 
    location_type, COUNT(location_type) AS records_per_type
FROM
    location
GROUP BY location_type;

SELECT 23740 / (15910 + 23740) * 100;

-- Diving into the sources

SELECT 
    *
FROM
    water_source;

SELECT 
   SUM(number_of_people_served) AS total_num_served
FROM
    water_source;
    
SELECT 
    type_of_water_source, COUNT(source_id) AS num_of_sources
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY num_of_sources DESC;

SELECT 
  type_of_water_source, ROUND(AVG(number_of_people_served)) AS avg_num_served
FROM
    water_source
GROUP BY type_of_water_source;

SELECT 
  type_of_water_source, SUM(number_of_people_served) AS total_people_served
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY total_people_served DESC;


SELECT 
  type_of_water_source, ROUND((SUM(number_of_people_served)/'27628140')*100) AS perct_people_served
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY perct_people_served DESC;

-- Start of a solution

SELECT 
  type_of_water_source,
  SUM(number_of_people_served) AS total_people_served,
  RANK() OVER ( ORDER BY SUM(number_of_people_served)DESC) AS ranka
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY total_people_served DESC;

SELECT 
  source_id,
  type_of_water_source,
  SUM(number_of_people_served) AS total_people_served,
  RANK() OVER ( ORDER BY SUM(number_of_people_served)DESC) AS ranka
FROM
    water_source
WHERE type_of_water_source <> "tap_in_home"
GROUP BY source_id
ORDER BY total_people_served DESC;

-- Analysing queues

SELECT 
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS num_of_days
FROM
    visits;
    
SELECT 
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS avg_time_in_queue
FROM
    visits;
    
    SELECT 
    DAYNAME(time_of_record) AS day_of_the_week,
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS avg_time_in_queue
FROM
    visits
GROUP BY day_of_the_week;

SELECT 
  TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_the_day,
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS avg_time_in_queue
FROM
    visits
GROUP BY hour_of_the_day
ORDER BY avg_time_in_queue DESC;

SELECT 
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Sunday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Monday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Tuesday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Wednesday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Thursday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Friday,
    ROUND(AVG(CASE
                WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
                ELSE NULL
            END),
            0) AS Saturday
FROM
    visits
WHERE
    time_in_queue != 0
GROUP BY 
    hour_of_day
ORDER BY 
    hour_of_day;
    
    -- mcqs

SELECT 
    CONCAT(DAY(time_of_record),
            ' ',
            MONTHNAME(time_of_record),
            ' ',
            YEAR(time_of_record)) AS date_format
FROM
    visits;
    
SELECT assigned_employee_id, COUNT(visit_count) AS num_of_visit
FROM visits
GROUP BY assigned_employee_id
ORDER BY num_of_visit ASC
LIMIT 2;

SELECT 
    *
FROM
    employee
WHERE
	assigned_employee_id IN (20, 22);
    
SELECT TRIM('33 Angelique Kidjo Avenue  ') AS trimmed_address;

SELECT town_name, COUNT(employee_name) AS number_of_employees
FROM employee 
WHERE town_name LIKE '%Dahabu%'
GROUP BY town_name;

SELECT town_name, COUNT(employee_name) AS number_of_employees
FROM employee 
WHERE town_name = 'Harare';


SELECT 
    ROUND(SUM(number_of_people_served) / COUNT(*)) AS average_people_per_well
FROM 
    water_source
WHERE 
    type_of_water_source = 'Well';
    
SELECT 
    SUM(number_of_people_served) AS total_people_served
FROM 
    water_source
WHERE type_of_water_source LIKE "%tap%"


    
    















