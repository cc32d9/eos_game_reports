CREATE DATABASE eosgames;

CREATE USER 'eosgames'@'localhost' IDENTIFIED BY 'Einie4xa';
GRANT ALL ON eosgames.* TO 'eosgames'@'localhost';

CREATE USER 'eosgamesro'@'%' IDENTIFIED BY 'eosgamesro';
GRANT SELECT ON eosgames.* TO 'eosgamesro'@'%';
