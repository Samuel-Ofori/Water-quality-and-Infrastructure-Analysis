CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

SELECT 
	location_id,
	true_water_source_score
FROM auditor_report;

-- join the visits table to the auditor_report table. Make sure to grab subjective_quality_score, record_id and location_id.
SELECT
a.location_id AS audit_location,
a.true_water_source_score,
v.location_id AS visit_location,
v.record_id
FROM
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id;

-- JOIN the visits table and the water_quality table, using the record_id as the connecting key.
SELECT
a.location_id AS audit_location,
a.true_water_source_score,
v.location_id AS visit_location,
v.record_id,
subjective_quality_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id; 

-- It doesn't matter if your columns are in a different format, because we are about to clean this up a bit. Since it is a duplicate, we can drop one of the location_id columns. Let's leave record_id and rename the scores to surveyor_score and auditor_score to make it clear which scores we're looking at in the results set.
SELECT
a.location_id AS location_id,
v.record_id,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id; 

SELECT
a.location_id AS location_id,
v.record_id,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
WHERE a.true_water_source_score = wq.subjective_quality_score;

-- You got 2505 rows right? Some of the locations were visited multiple times, so these records are duplicated here. To fix it, we set visits.visit_count= 1 in the WHERE clause. Make sure you reference the alias you used for visits in the join.
SELECT
a.location_id AS location_id,
v.record_id,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND
a.true_water_source_score = wq.subjective_quality_score;

-- With the duplicates removed I now get 1518. What does this mean considering the auditor visited 1620 sites? But that means that 102 records are incorrect. So let's look at those. You can do it by adding one character in the last query!
SELECT
a.location_id AS location_id,
v.record_id,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND
a.true_water_source_score <> wq.subjective_quality_score;

-- So, to do this, we need to grab the type_of_water_source column from the water_source table and call it survey_source, using the source_id column to JOIN. Also select the type_of_water_source from the auditor_report table, and call it auditor_source.
SELECT
a.location_id AS location_id,
a.type_of_water_source AS auditor_source,
ws.type_of_water_source AS surveyor_source,
v.record_id,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN water_source ws
ON ws.source_id = v.source_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score;

-- JOIN the assigned_employee_id for all the people on our list from the visits table to our query. Remember, our query shows the shows the 102 incorrect records, so when we join the employee data, we can see which employees made these incorrect records.
SELECT
a.location_id AS location_id,
v.record_id,
v.assigned_employee_id,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score;

-- So now we can link the incorrect records to the employees who recorded them. The ID's don't help us to identify them. We have employees' names stored along with their IDs, so let's fetch their names from the employees table instead of the ID's.
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score;

-- Well this query is massive and complex, so maybe it is a good idea to save this as a CTE, so when we do more analysis, we can just call that CTE like it was a table. Call it something like Incorrect_records. Once you are done, check if this query SELECT * FROM Incorrect_records, gets the same table back.
WITH Incorrect_records AS(
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score
)
SELECT *
FROM Incorrect_records;

-- Let's first get a unique list of employees from this table.
WITH Incorrect_records AS(
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score
)
SELECT DISTINCT employee_name
FROM Incorrect_records; 

-- Let's first get a unique list of employees from this table.
WITH Incorrect_records AS(
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score
)
SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name;

-- So let's try to find all of the employees who have an above-average number of mistakes. Let's break it down into steps first: 1. We have to first calculate the number of times someone's name comes up. (we just did that in the previous query). Let's call it error_count.
WITH error_count AS(
SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM (
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score
) AS incorrect_records
GROUP BY employee_name
)
SELECT *
FROM error_count;

-- 2. average number of mistakes employees made. We can do that by taking the average of the previous query's results.
WITH error_count AS(
SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM (
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score
) AS incorrect_records
GROUP BY employee_name
)
SELECT AVG(number_of_mistakes) as avg_error_count_per_empl
FROM error_count;

-- 3. Finaly we have to compare each employee's error_count with avg_error_count_per_empl. We will call this results set our suspect_list. Remember that we can't use an aggregate result in WHERE, so we have to use avg_error_count_per_empl as a subquery.
WITH error_count AS(
SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM (
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score != wq.subjective_quality_score
) AS incorrect_records
GROUP BY employee_name
)
SELECT
employee_name,
number_of_mistakes
FROM error_count
WHERE number_of_mistakes >  (SELECT AVG(number_of_mistakes) as avg_error_count_per_empl
FROM error_count);

-- Convert Incorrect_records to a view
CREATE VIEW Incorrect_records AS (
SELECT
a.location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score,
a.statements AS statements
FROM
auditor_report a
JOIN
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN
employee e
ON e.assigned_employee_id = v.assigned_employee_id
WHERE
v.visit_count = 1
AND a.true_water_source_score != wq.subjective_quality_score);

SELECT * FROM incorrect_records;

-- convert the suspect_list to a CTE
WITH suspect_list AS(
SELECT
employee_name,
number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) as avg_error_count_per_empl FROM error_count)
) 
SELECT * 
FROM suspect_list;

CREATE VIEW error_count AS(
SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM (
SELECT
a.location_id AS location_id,
v.record_id,
e.employee_name,
a.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM 
auditor_report a
JOIN 
visits v
ON a.location_id = v.location_id
JOIN
water_quality wq
ON v.record_id = wq.record_id
JOIN 
employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND
a.true_water_source_score <> wq.subjective_quality_score
) AS incorrect_records
GROUP BY employee_name
);
























