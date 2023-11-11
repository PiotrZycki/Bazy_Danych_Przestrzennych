--0
CREATE TABLE obiekty(id int, nazwa text, geometria GEOMETRY);
SELECT * FROM obiekty;
DROP TABLE obiekty;

--obiekt 1
INSERT INTO obiekty VALUES(
	1,
	'obiekt 1',
	ST_GeomFromEWKT(
		'COMPOUNDCURVE(
			(0 1, 1 1),
			CIRCULARSTRING(1 1, 2 0, 3 1),
			CIRCULARSTRING(3 1, 4 2, 5 1),
			(5 1, 6 1)
		)'
	)
);

--obiekt 2
INSERT INTO obiekty VALUES(
	2,
	'obiekt 2',
	ST_GeomFromEWKT(
		'CURVEPOLYGON(
			COMPOUNDCURVE(
				(10 6, 14 6),
				CIRCULARSTRING(14 6, 16 4, 14 2),
				CIRCULARSTRING(14 2, 12 0, 10 2),
				(10 2, 10 6)
			),
			CIRCULARSTRING(11 2, 13 2, 11 2)
		)'
	)
);

--obiekt 3
INSERT INTO obiekty VALUES(
	3,
	'obiekt 3',
	ST_GeomFromEWKT(
		'TRIANGLE((7 15, 10 17, 12 13, 7 15))'
	)
);

--obiekt 4
INSERT INTO obiekty VALUES(
	4,
	'obiekt 4',
	ST_GeomFromEWKT(
		'MULTILINESTRING(
			(20 20, 25 25), 
			(25 25, 27 24), 
			(27 24, 25 22), 
			(25 22, 26 21), 
			(26 21, 22 19), 
			(22 19, 20.5 19.5)
		)'
	)
);

--obiekt 5
INSERT INTO obiekty VALUES(
	5,
	'obiekt 5',
	ST_GeomFromEWKT(
		'MULTIPOINT(
			(30 30 59),
			(38 32 234)
		)'
	)
);

--obiekt 6
INSERT INTO obiekty VALUES(
	6,
	'obiekt 6',
	ST_GeomFromEWKT(
		'GEOMETRYCOLLECTION(
			LINESTRING(1 1, 3 2),
			POINT(4 2)
		)'
	)
);


--1
SELECT ST_Area(
	ST_Buffer(
		ST_ShortestLine(
			(SELECT geometria FROM obiekty WHERE nazwa='obiekt 3'),
			(SELECT geometria FROM obiekty WHERE nazwa='obiekt 4')
		),
		5
	)
);

--2
UPDATE obiekty 
SET geometria = ST_MakePolygon(
	ST_LineMerge(
		ST_GeomFromEWKT(
			'MULTILINESTRING(
				(20 20, 25 25), 
				(25 25, 27 24), 
				(27 24, 25 22), 
				(25 22, 26 21), 
				(26 21, 22 19), 
				(22 19, 20.5 19.5),
				(20.5 19.5, 20 20)
			)'
		)
	)
)
WHERE nazwa='obiekt 4';


--3
--obiekt 7
INSERT INTO obiekty VALUES(
	7,
	'obiekt 7',
	ST_Collect(
		(SELECT geometria FROM obiekty WHERE nazwa='obiekt 3'),
		(SELECT geometria FROM obiekty WHERE nazwa='obiekt 4')
	)
);

--4
SELECT ST_Area(ST_Union(ST_Buffer(geometria,5))) FROM obiekty WHERE ST_HasArc(geometria)!=TRUE;

