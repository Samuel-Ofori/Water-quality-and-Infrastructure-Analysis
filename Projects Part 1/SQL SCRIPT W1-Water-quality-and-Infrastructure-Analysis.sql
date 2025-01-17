USE md_water_services;

SELECT 
    *
FROM
    data_dictionary
LIMIT 10;

-- Dive into the water sources

SELECT 
	*
FROM
    water_source;
    
SELECT 
    *
FROM
    visits;
/* WHERE
	time_in_queue > 500 */
    
SELECT 
    *
FROM
    water_quality
WHERE subjective_quality_score = 10 AND visit_count =  2;

SELECT 
    *
FROM
    well_pollution
LIMIT 5;

SELECT 
    *
FROM
    well_pollution
WHERE
    results = 'clean' AND biological > 0.01 AND description LIKE "%clean%";
    
UPDATE
	well_pollution
SET
	description = "Bacteria: E. coli"
WHERE description = "Clean Bacteria: E. coli";

SET SQL_SAFE_UPDATES = 0;

UPDATE
	well_pollution
SET
	description = "Bacteria: Giardia Lamblia"
WHERE description = "Clean Bacteria: Giardia Lamblia";


UPDATE
	well_pollution
SET
	results = "Contaminated: Biological"
WHERE biological > 0.01 AND results = "Clean";

SELECT 
    *
FROM
    well_pollution
WHERE
    description LIKE '&clean&'
        OR (results = 'clean' AND biological > 0.01);
        
SELECT 
	*
FROM
    location
WHERE
    name = "Bello Azibo";