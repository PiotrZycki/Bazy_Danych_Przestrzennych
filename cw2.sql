--3
CREATE EXTENSION postgis;

--4
CREATE TABLE budynki(id int, geometria GEOMETRY, nazwa text);
CREATE TABLE drogi(id int, geometria GEOMETRY, nazwa text);
CREATE TABLE punkty_informacyjne(id int, geometria GEOMETRY, nazwa text);

--6
INSERT INTO budynki VALUES 
	(1, ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))'), 'BuildingA'),
	(2, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))'), 'BuildingB'),
	(3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))'), 'BuildingC'),
	(4, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))'), 'BuildingD'),
	(5, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))'), 'BuildingF');

INSERT INTO drogi VALUES 
	(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX'),
	(2, ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)'), 'RoadY');

INSERT INTO punkty_informacyjne VALUES 
	(1, ST_GeomFromText('POINT(1.0 3.5)'), 'G'),
	(2, ST_GeomFromText('POINT(5.5 1.5)'), 'H'),
	(3, ST_GeomFromText('POINT(9.5 6.0)'), 'I'),
	(4, ST_GeomFromText('POINT(6.5 6.0)'), 'J'),
	(5, ST_GeomFromText('POINT(6.0 9.5)'), 'K');
	
SELECT * FROM budynki;
SELECT * FROM drogi;
SELECT * FROM punkty_informacyjne;

--6a
SELECT SUM(ST_Length(geometria)) AS suma FROM drogi;

--6b
SELECT ST_AsText(geometria) AS wkt, ST_Area(geometria) AS pole, ST_Perimeter(geometria) AS obwod FROM budynki WHERE nazwa='BuildingA';


--6c
SELECT nazwa, ST_Area(geometria) AS pole FROM budynki ORDER BY nazwa;

--6d
SELECT nazwa, ST_Perimeter(geometria) AS obwod FROM budynki ORDER BY ST_Area(geometria) desc LIMIT 2;

--6e
SELECT ST_Distance((SELECT geometria FROM budynki WHERE nazwa='BuildingC'), (SELECT geometria FROM punkty_informacyjne WHERE nazwa='G')) AS najkrotsza_odleglosc;

--6f
SELECT ST_Area((SELECT geometria FROM budynki WHERE nazwa='BuildingC')) - ST_Area(ST_Intersection(
	ST_Buffer((SELECT geometria FROM budynki WHERE nazwa='BuildingB'), 0.5),(SELECT geometria FROM budynki WHERE nazwa='BuildingC'))) AS pole;

--6g
SELECT nazwa FROM budynki WHERE ST_Contains(ST_Buffer((SELECT geometria FROM drogi WHERE nazwa='RoadX'), 100, 'side=left'), ST_Centroid(geometria));

--6h
SELECT ST_Area((SELECT geometria FROM budynki WHERE nazwa='BuildingC')) 
	  + ST_Area('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'::geometry)
	- 2*ST_Area(ST_Intersection((SELECT geometria FROM budynki WHERE nazwa='BuildingC'), 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'::geometry)) AS pole;
