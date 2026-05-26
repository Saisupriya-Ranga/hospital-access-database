CREATE USER 'hospital_access'@'localhost' IDENTIFIED BY 'dbmshospitalproject!';
GRANT SELECT ON hospital_county_distance.* TO 'hospital_access'@'localhost';


SELECT User, Host FROM mysql.user WHERE User = 'hospital_access';