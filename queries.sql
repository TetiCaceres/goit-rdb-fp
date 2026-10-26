CREATE SCHEMA IF NOT EXISTS pandemic;
USE pandemic;


DROP TABLE IF EXISTS infectious_cases;

CREATE TABLE infectious_cases (
  Entity VARCHAR(100),
  Code VARCHAR(10) NULL,
  Year INT,
  Number_yaws DOUBLE NULL,
  polio_cases DOUBLE NULL,
  cases_guinea_worm DOUBLE NULL,
  Number_rabies DOUBLE NULL,
  Number_malaria DOUBLE NULL,
  Number_hiv DOUBLE NULL,
  Number_tuberculosis DOUBLE NULL,
  Number_smallpox DOUBLE NULL,
  Number_cholera_cases DOUBLE NULL
);

LOAD DATA LOCAL INFILE '/Users/tetiana/Desktop/goIT/DB/infectious_cases.csv'
INTO TABLE infectious_cases
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Entity, @Code, Year, @yaws, @polio, @gw, @rabies, @malaria, @hiv, @tb, @smallpox, @cholera)
SET Code = NULLIF(@Code,''),
    Number_yaws = NULLIF(@yaws,''),
    polio_cases = NULLIF(@polio,''),
    cases_guinea_worm = NULLIF(@gw,''),
    Number_rabies = NULLIF(@rabies,''),
    Number_malaria = NULLIF(@malaria,''),
    Number_hiv = NULLIF(@hiv,''),
    Number_tuberculosis = NULLIF(@tb,''),
    Number_smallpox = NULLIF(@smallpox,''),
    Number_cholera_cases = NULLIF(@cholera,'');
    
SELECT *
FROM infectious_cases
LIMIT 10;
    
SELECT COUNT(*) FROM infectious_cases;  

DESCRIBE infectious_cases;

-- =========================================
-- TASK 2. Normalization
-- =========================================
   
DROP TABLE IF EXISTS infectious_cases_normalized;
DROP TABLE IF EXISTS entities;

CREATE TABLE entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Entity VARCHAR(100) NOT NULL,
    Code VARCHAR(10) NULL,
    UNIQUE KEY uq_entity_code (Entity, Code)
);

INSERT INTO entities (entity, code)
SELECT DISTINCT 
    Entity, 
    NULLIF(Code, '') 
FROM infectious_cases
ORDER BY Entity;
  
  SELECT *
FROM entities;

SELECT COUNT(*)
FROM entities;


-- 2.2 Create Normalized Fact Table: `infectious_cases_normalized`
CREATE TABLE infectious_cases_normalized (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT NOT NULL,
    year INT NOT NULL,
    number_yaws INT NULL,
    polio_cases INT NULL,
    cases_guinea_worm INT NULL,
    number_rabies DOUBLE NULL,
    number_malaria DOUBLE NULL,
    number_hiv DOUBLE NULL,
    number_tuberculosis DOUBLE NULL,
    number_smallpox INT NULL,
    number_cholera_cases INT NULL,
    CONSTRAINT fk_cases_entity FOREIGN KEY (entity_id) REFERENCES entities(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

INSERT INTO infectious_cases_normalized (
    entity_id, year, number_yaws, polio_cases, cases_guinea_worm,
    number_rabies, number_malaria, number_hiv, number_tuberculosis,
    number_smallpox, number_cholera_cases
)
SELECT 
    e.id,
    ic.Year,
    NULLIF(ic.Number_yaws, ''),
    NULLIF(ic.polio_cases, ''),
    NULLIF(ic.cases_guinea_worm, ''),
    NULLIF(ic.Number_rabies, ''),
    NULLIF(ic.Number_malaria, ''),
    NULLIF(ic.Number_hiv, ''),
    NULLIF(ic.Number_tuberculosis, ''),
    NULLIF(ic.Number_smallpox, ''),
    NULLIF(ic.Number_cholera_cases, '')
FROM infectious_cases ic
JOIN entities e ON ic.Entity = e.entity AND e.Code <=> ic.Code;



-- Verification of 3NF tables:
SELECT COUNT(*) AS total_entities FROM entities;
SELECT COUNT(*) AS total_normalized_cases FROM infectious_cases_normalized;


-- =========================================
-- TASK 3. Number_rabies analysis
-- =========================================
   
SELECT
    e.id,
    e.Entity,
    e.Code,
    AVG(icn.Number_rabies) AS avg_rabies,
    MIN(icn.Number_rabies) AS min_rabies,
    MAX(icn.Number_rabies) AS max_rabies,
    SUM(icn.Number_rabies) AS sum_rabies
FROM infectious_cases_normalized icn
JOIN entities e
    ON icn.entity_id = e.id
WHERE icn.Number_rabies IS NOT NULL
GROUP BY
    e.id,
    e.Entity,
    e.Code
ORDER BY avg_rabies DESC
LIMIT 10;



-- =========================================
-- TASK 4. Creating a column for the difference in years
-- =========================================
SELECT
    Year,
    MAKEDATE(Year, 1) AS year_start,
    CURRENT_DATE() AS today,
    TIMESTAMPDIFF(
        YEAR,
        MAKEDATE(Year, 1),
        CURRENT_DATE()
    ) AS year_difference
FROM infectious_cases_normalized
WHERE Year IS NOT NULL;



-- =========================================
-- TASK 5. Creating function
-- =========================================
DROP FUNCTION IF EXISTS calculate_year_difference;

DELIMITER //

CREATE FUNCTION calculate_year_difference(input_year INT)
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN
    IF input_year IS NULL
       OR input_year < 1000
       OR input_year > 9999 THEN
        RETURN NULL;
    END IF;

    RETURN TIMESTAMPDIFF(
        YEAR,
        MAKEDATE(input_year, 1),
        CURRENT_DATE()
    );
END//

DELIMITER ;

SELECT calculate_year_difference(1996) AS year_difference;
SELECT
    Year,
    calculate_year_difference(Year) AS year_difference
FROM infectious_cases
WHERE Year IS NOT NULL
LIMIT 10;
