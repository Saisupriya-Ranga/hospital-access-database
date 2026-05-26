CREATE DATABASE hospital_county_distance; 

USE hospital_county_distance;

CREATE TABLE Hospital (
  HospitalId INT PRIMARY KEY AUTO_INCREMENT,
  Name VARCHAR(255),
  Address VARCHAR(255),
  City VARCHAR(100),
  State VARCHAR(50),
  Latitude FLOAT,
  Longitude FLOAT,
  Type VARCHAR(100),
  Beds INT,
  EmergencyServices VARCHAR(50),
  Ownership VARCHAR(100),
  Status VARCHAR(50)
);

ALTER TABLE Hospital ADD ZIPCode VARCHAR(10);

CREATE TABLE Hospital_Locations_Raw (
  ID VARCHAR(50),
  NAME VARCHAR(255),
  ADDRESS VARCHAR(255),
  CITY VARCHAR(100),
  STATE VARCHAR(50),
  TYPE VARCHAR(100),
  STATUS VARCHAR(50),
  LATITUDE FLOAT,
  LONGITUDE FLOAT,
  OWNER VARCHAR(100),
  BEDS INT,
  HELIPAD VARCHAR(50)
);

DROP TABLE Hospital_Locations_Raw;

CREATE TABLE Hospital_Info_Raw (
  ProviderID VARCHAR(50),
  HospitalName VARCHAR(255),
  Address VARCHAR(255),
  City VARCHAR(100),
  State VARCHAR(50),
  ZIPCode VARCHAR(10),
  HospitalType VARCHAR(100),
  HospitalOwnership VARCHAR(100),
  EmergencyServices VARCHAR(50)
  -- Add other columns if needed
);

DROP TABLE Hospital_Info_Raw;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/Users/saisupriyaranga/Downloads/hospital_locations.csv'
INTO TABLE Hospital_Locations_Raw
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/saisupriyaranga/Downloads/Hospital_General_Information.csv'
INTO TABLE Hospital_Info_Raw
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW COLUMNS FROM Hospital_Locations_Raw;
SHOW COLUMNS FROM Hospital_Info_Raw;

SELECT NAME, ADDRESS, CITY, STATE FROM Hospital_Locations_Raw LIMIT 5;
SELECT HospitalName, Address, City, State FROM Hospital_Info_Raw LIMIT 5;

SELECT COUNT(*) FROM Hospital_Locations_Raw;
SELECT COUNT(*) FROM Hospital_Info_Raw;

ALTER TABLE Hospital_Locations_Raw ADD match_key VARCHAR(500);
ALTER TABLE Hospital_Info_Raw ADD match_key VARCHAR(500);

UPDATE Hospital_Locations_Raw
SET match_key = CONCAT(
  LOWER(TRIM(REPLACE(NAME, '"', ''))), '_',
  LOWER(TRIM(REPLACE(ADDRESS, '"', ''))), '_',
  LOWER(TRIM(CITY)), '_',
  LOWER(TRIM(STATE))
);

UPDATE Hospital_Info_Raw
SET match_key = CONCAT(
  LOWER(TRIM(REPLACE(HospitalName, '"', ''))), '_',
  LOWER(TRIM(REPLACE(Address, '"', ''))), '_',
  LOWER(TRIM(City)), '_',
  LOWER(TRIM(State))
);

SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*)
FROM Hospital_Locations_Raw hl
JOIN Hospital_Info_Raw hi
  ON hl.match_key = hi.match_key;


INSERT INTO Hospital (
  Name, Address, City, State, ZIPCode, Latitude, Longitude,
  Type, Beds, EmergencyServices, Ownership, Status
)
SELECT 
  hl.NAME, hl.ADDRESS, hl.CITY, hl.STATE, hi.ZIPCode,
  hl.LATITUDE, hl.LONGITUDE, hl.TYPE, hl.BEDS,
  hi.EmergencyServices, hi.HospitalOwnership, hl.STATUS
FROM Hospital_Locations_Raw hl
JOIN Hospital_Info_Raw hi
  ON hl.match_key = hi.match_key;

SELECT COUNT(*) FROM Hospital;

SELECT * FROM Hospital LIMIT 10;

-- COUNTY DATA
CREATE TABLE County (
  CountyId INT PRIMARY KEY,
  Name VARCHAR(100),
  State VARCHAR(50),
  TotalPopulation INT,
  PovertyRate FLOAT,
  Unemployment FLOAT,
  Latitude FLOAT,
  Longitude FLOAT
);

CREATE TABLE County_Data_Raw (
  CountyId INT PRIMARY KEY,
  State VARCHAR(50),
  Name VARCHAR(100),
  TotalPopulation INT,
  PovertyRate FLOAT,
  Unemployment FLOAT
);

LOAD DATA LOCAL INFILE '/Users/saisupriyaranga/Downloads/county_data.csv'
INTO TABLE County_Data_Raw
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE County_Centroid_Raw (
  CountyId INT PRIMARY KEY,
  CountyName VARCHAR(100),
  State VARCHAR(50),
  Latitude FLOAT,
  Longitude FLOAT
);

DROP TABLE County_Centroid_Raw;

LOAD DATA LOCAL INFILE '/Users/saisupriyaranga/Downloads/County_Centroids_data.csv'
INTO TABLE County_Centroid_Raw
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM County_Centroid_Raw;
SELECT COUNT(*) FROM County_Data_Raw;

SELECT * FROM County_Centroid_Raw LIMIT 5;

DELETE FROM County_Centroid_Raw WHERE CountyId = 0;

SELECT * FROM County_Data_Raw LIMIT 5;

INSERT INTO County (
  CountyId, Name, State, TotalPopulation, PovertyRate, Unemployment, Latitude, Longitude
)
SELECT 
  d.CountyId, d.Name, d.State, d.TotalPopulation, d.PovertyRate, d.Unemployment,
  c.Latitude, c.Longitude
FROM County_Data_Raw d
JOIN County_Centroid_Raw c
  ON d.CountyId = c.CountyId;
  
SELECT COUNT(*) FROM County;

SELECT * FROM County LIMIT 10;

CREATE TABLE Hospital_County_Distance (
  Hospital_County_Distance_Id INT PRIMARY KEY AUTO_INCREMENT,
  HospitalId INT,
  CountyId INT,
  Hospital_County_Distance_Miles FLOAT,
  FOREIGN KEY (HospitalId) REFERENCES Hospital(HospitalId),
  FOREIGN KEY (CountyId) REFERENCES County(CountyId)
);

INSERT INTO Hospital_County_Distance (HospitalId, CountyId, Hospital_County_Distance_Miles)
SELECT 
  h.HospitalId,
  c.CountyId,
  3959 * ACOS(
    COS(RADIANS(c.Latitude)) * COS(RADIANS(h.Latitude)) *
    COS(RADIANS(h.Longitude) - RADIANS(c.Longitude)) +
    SIN(RADIANS(c.Latitude)) * SIN(RADIANS(h.Latitude))
  ) AS Hospital_County_Distance_Miles
FROM Hospital h
JOIN County c;

SELECT COUNT(*) FROM Hospital;  -- 1814
SELECT COUNT(*) FROM County;    -- 3135

SELECT COUNT(*) FROM Hospital_County_Distance; -- 1814 hospitals × 3135 counties = 5686890
SELECT * FROM Hospital_County_Distance LIMIT 10;

-- We can count the hospitals that are closed
SELECT COUNT(*) FROM Hospital WHERE Status = 'Closed';

-- We should find the nearest hospital to each county that is only open

-- 1. Nearest Hospital for Each County
SELECT 
	hcd.CountyId,
	hcd.HospitalId,
	hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance hcd
JOIN Hospital h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open';

SELECT COUNT(*)
  -- hcd.CountyId,
--   hcd.HospitalId,
--   hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance hcd
JOIN Hospital h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open'; -- 3078

-- 2. Counties with No Hospital Within 30 Miles -- UNDERSERVED COUNTIES
SELECT COUNT(*) AS FarCounties
FROM (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance hcd
  JOIN Hospital h ON hcd.HospitalId = h.HospitalId
  WHERE h.Status = 'Open'
  GROUP BY hcd.CountyId
) nearest
WHERE MinDistance > 30; -- 781

SELECT 
  c.CountyId,
  c.Name,
  c.State,
  nearest.MinDistance
FROM (
  SELECT hcd.CountyId, MIN(hcd.Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance hcd
  JOIN Hospital h ON hcd.HospitalId = h.HospitalId
  WHERE h.Status = 'Open'
  GROUP BY hcd.CountyId
) nearest
JOIN County c ON nearest.CountyId = c.CountyId
WHERE nearest.MinDistance > 30
ORDER BY nearest.MinDistance DESC;


-- 3. Hospitals Serving the Most Counties Within 30 Miles
SELECT 
  h.HospitalId,
  h.Name,
  COUNT(*) AS CountiesServed
FROM Hospital_County_Distance hcd
JOIN Hospital h ON hcd.HospitalId = h.HospitalId
WHERE hcd.Hospital_County_Distance_Miles <= 30
  AND h.Status = 'Open'
GROUP BY h.HospitalId, h.Name
ORDER BY CountiesServed DESC
LIMIT 10;

-- Top 5 counties with best access (shortest distance)
SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
FROM Hospital_County_Distance
GROUP BY CountyId
ORDER BY MinDistance ASC
LIMIT 5;

-- Bottom 5 counties with worst access
SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
FROM Hospital_County_Distance
GROUP BY CountyId
ORDER BY MinDistance DESC
LIMIT 5;

-- Average nearest hospital distance
SELECT AVG(MinDistance) AS AvgNearestDistance
FROM (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance
  GROUP BY CountyId
) AS nearest;

-- Outliers in hospital access = Flags counties that may need urgent policy attention.
SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
FROM Hospital_County_Distance
GROUP BY CountyId
HAVING MinDistance > 100;


-- Indexing :
-- Index for filtering hospitals by status
CREATE INDEX idx_status ON Hospital(Status);

-- Index for joining and grouping by CountyId
CREATE INDEX idx_county ON Hospital_County_Distance(CountyId);

-- Index for joining and grouping by HospitalId
CREATE INDEX idx_hospital ON Hospital_County_Distance(HospitalId);

-- Composite index for frequent distance queries
CREATE INDEX idx_county_distance ON Hospital_County_Distance(CountyId, Hospital_County_Distance_Miles);

-- Profiling :
SET profiling = 1;

SELECT 
	hcd.CountyId,
	hcd.HospitalId,
	hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance hcd
JOIN Hospital h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open';

SHOW PROFILES;

EXPLAIN SELECT 
  hcd.CountyId,
  hcd.HospitalId,
  hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance hcd
JOIN Hospital h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open';


DROP INDEX idx_status ON Hospital;
DROP INDEX idx_county ON Hospital_County_Distance;
DROP INDEX idx_hospital ON Hospital_County_Distance;
DROP INDEX idx_county_distance ON Hospital_County_Distance;


SHOW INDEX FROM Hospital_County_Distance;
SHOW INDEX FROM Hospital;


SET profiling = 1;

SELECT 
  hcd.CountyId,
  hcd.HospitalId,
  hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance hcd
JOIN Hospital h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open';

SHOW PROFILES;





CREATE TABLE Hospital_County_Distance_NoIndex AS
SELECT * FROM Hospital_County_Distance;

CREATE TABLE Hospital_NoIndex AS
SELECT * FROM Hospital;

SET profiling = 1;
SELECT 
  hcd.CountyId,
  hcd.HospitalId,
  hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance_NoIndex hcd
JOIN Hospital_NoIndex h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance_NoIndex
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open';

SHOW PROFILES;

EXPLAIN SELECT 
  hcd.CountyId,
  hcd.HospitalId,
  hcd.Hospital_County_Distance_Miles
FROM Hospital_County_Distance_NoIndex hcd
JOIN Hospital_NoIndex h ON hcd.HospitalId = h.HospitalId
JOIN (
  SELECT CountyId, MIN(Hospital_County_Distance_Miles) AS MinDistance
  FROM Hospital_County_Distance_NoIndex
  GROUP BY CountyId
) nearest
ON hcd.CountyId = nearest.CountyId
AND hcd.Hospital_County_Distance_Miles = nearest.MinDistance
WHERE h.Status = 'Open';


DROP TABLE Hospital_County_Distance_NoIndex;
DROP TABLE Hospital_NoIndex;



