
CREATE DATABASE IF NOT EXISTS SummerCamp;
USE SummerCamp;


CREATE TABLE Participants (
    ParticipantID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    MiddleName VARCHAR(50) NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Gender ENUM('Male', 'Female') NOT NULL,
    Phone VARCHAR(15) UNIQUE NOT NULL
);


CREATE TABLE Camps (
    CampID INT AUTO_INCREMENT PRIMARY KEY,
    CampTitle VARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Price DECIMAL(8,2) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0)
);


CREATE TABLE VisitRecords (
    VisitID INT AUTO_INCREMENT PRIMARY KEY,
    ParticipantID INT,
    CampID INT,
    VisitDate DATE NOT NULL,
    FOREIGN KEY (ParticipantID) REFERENCES Participants(ParticipantID) ON DELETE CASCADE,
    FOREIGN KEY (CampID) REFERENCES Camps(CampID) ON DELETE CASCADE
);


DELIMITER $$

CREATE PROCEDURE PopulateParticipants()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE randGender ENUM('Male', 'Female');
    DECLARE randAge INT;
    WHILE i < 5000 DO
        -- Assign gender based on 65% female and 35% male
        SET randGender = IF(RAND() < 0.65, 'Female', 'Male');

        -- Assign age according to specified distributions
        SET randAge = CASE 
            WHEN RAND() < 0.18 THEN FLOOR(7 + (RAND() * 6))  -- 7-12 years (18%)
            WHEN RAND() < 0.45 THEN FLOOR(13 + (RAND() * 2)) -- 13-14 years (27%)
            WHEN RAND() < 0.65 THEN FLOOR(15 + (RAND() * 3)) -- 15-17 years (20%)
            ELSE FLOOR(18 + (RAND() * 2))                    -- 18-19 years (35%)
        END;

        INSERT INTO Participants (FirstName, MiddleName, LastName, DateOfBirth, Email, Gender, Phone)
        VALUES (
            IF(randGender = 'Female', 
                ELT(FLOOR(1 + (RAND() * 10)), 'Emma', 'Olivia', 'Ava', 'Sophia', 'Isabella', 'Lakshmi', 'Mia', 'Charlotte', 'Amelia', 'Harper'), 
                ELT(FLOOR(1 + (RAND() * 10)), 'Liam', 'Noah', 'Oliver', 'Elijah', 'James', 'Lucas', 'Mason', 'Ethan', 'Logan', 'Aiden')
            ),
            NULL,
            ELT(FLOOR(1 + (RAND() * 10)), 'Smith', 'Johnson', 'Brown', 'Taylor', 'Anderson', 'Thomas', 'Harris', 'Martin', 'Thompson', 'Garcia'),
            DATE_SUB(CURDATE(), INTERVAL randAge YEAR),
            CONCAT(SUBSTRING(MD5(RAND()), 1, 8), '@example.com'),
            randGender,
            CONCAT('+1', FLOOR(1000000000 + (RAND() * 9000000000)))
        );

        SET i = i + 1;
    END WHILE;
END $$

DELIMITER ;

CALL PopulateParticipants();


INSERT INTO Camps (CampTitle, StartDate, EndDate, Price, Capacity)
SELECT 
    ELT(FLOOR(1 + (RAND() * 5)), 'Adventure Camp', 'Science Camp', 'Arts Camp', 'Sports Camp', 'Music Camp') AS CampTitle,
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 36) MONTH) AS StartDate,
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 36) MONTH), INTERVAL 7 DAY) AS EndDate,
    FLOOR(200 + (RAND() * 500)) AS Price,
    FLOOR(10 + (RAND() * 50)) AS Capacity
FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS tmp
LIMIT 20;

-- Insert Visit Records Over 3 Years
DELIMITER $$

CREATE PROCEDURE PopulateVisits()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE pID INT;
    DECLARE cur CURSOR FOR SELECT ParticipantID FROM Participants;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    visit_loop: LOOP
        FETCH cur INTO pID;
        IF done THEN
            LEAVE visit_loop;
        END IF;
        
        INSERT INTO VisitRecords (ParticipantID, CampID, VisitDate)
        SELECT 
            pID,
            (SELECT CampID FROM Camps ORDER BY RAND() LIMIT 1),
            DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 36) MONTH)
        FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3) AS tmp;
    END LOOP;
    
    CLOSE cur;
END $$

DELIMITER ;

CALL PopulateVisits();

-- Ensure Lakshmi has Visit Records
INSERT INTO VisitRecords (ParticipantID, CampID, VisitDate)
SELECT 
    p.ParticipantID,
    (SELECT CampID FROM Camps ORDER BY RAND() LIMIT 1),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 12) MONTH)
FROM Participants p
WHERE p.FirstName = 'Lakshmi'
ORDER BY RAND()
LIMIT 5;
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, DateOfBirth, CURDATE()) BETWEEN 7 AND 12 THEN '7-12'
        WHEN TIMESTAMPDIFF(YEAR, DateOfBirth, CURDATE()) BETWEEN 13 AND 14 THEN '13-14'
        WHEN TIMESTAMPDIFF(YEAR, DateOfBirth, CURDATE()) BETWEEN 15 AND 17 THEN '15-17'
        ELSE '18-19'
    END AS AgeGroup,
    Gender,
    COUNT(*) AS Count
FROM Participants
GROUP BY AgeGroup, Gender
ORDER BY AgeGroup, Gender;



