--z1
SELECT nb.* 
FROM t2019_kar_buildings nb 
WHERE NOT EXISTS (
	SELECT ob.polygon_id FROM t2018_kar_buildings ob WHERE nb.geom = ob.geom 
);


--z2
WITH buildings
AS
(
	SELECT nb.geom 
	FROM t2019_kar_buildings nb 
	WHERE NOT EXISTS (
		SELECT ob.polygon_id FROM t2018_kar_buildings ob WHERE nb.geom = ob.geom 
	)
),
points
AS
(
	SELECT np.* 
	FROM t2019_kar_poi_table np 
	WHERE NOT EXISTS (
		SELECT op.poi_id FROM t2018_kar_poi_table op WHERE np.geom = op.geom 
	)
)
SELECT points.type, COUNT(ST_DWithin(points.geom, buildings.geom, 500)) 
FROM buildings, points 
GROUP BY points.type;


--z3
SELECT * INTO streets_reprojected FROM t2019_kar_streets;
SELECT UpdateGeometrySRID('streets_reprojected', 'geom', 3068);

SELECT Find_SRID('public', 'streets_reprojected', 'geom');

SELECT * FROM streets_reprojected;


--z4
CREATE TABLE input_points(id int, nazwa text, geometria GEOMETRY);

INSERT INTO input_points VALUES 
	(1, 'PointA', ST_GeomFromText('POINT(8.36093 49.03174)', 4326)),
	(2, 'PointB', ST_GeomFromText('POINT(8.39876 49.00644)', 4326));

SELECT * FROM input_points;


--z5
SELECT UpdateGeometrySRID('input_points', 'geometria', 3068);
SELECT ST_AsText(geometria) FROM input_points;

SELECT Find_SRID('public', 'input_points', 'geometria');


--z6
SELECT * FROM t2019_kar_street_node sn 
WHERE ST_DWithin(sn.geom,ST_transform(
	ST_ShortestLine(
	(SELECT geometria FROM input_points ip LIMIT 1 ), 
	(SELECT geometria FROM input_points ip ORDER BY ip.id desc LIMIT 1 )),4326),200) AND sn.intersect='Y';

SELECT sn.* FROM t2019_kar_street_node sn 
WHERE ST_DWithin(ST_Transform(sn.geom,3068),
	ST_ShortestLine(
	(SELECT geometria FROM input_points ip LIMIT 1 ), 
	(SELECT geometria FROM input_points ip ORDER BY ip.id desc LIMIT 1 )),20000) 
	AND sn.intersect='Y';
	
--z7
SELECT COUNT(DISTINCT sp.*) 
FROM t2019_kar_poi_table sp, t2019_kar_land_use_a pa 
WHERE ST_DWithin(sp.geom, pa.geom, 300) 
	AND sp.type = 'Sporting Goods Store' 
	AND pa.type='Park (City/County)';


--z8
SELECT DISTINCT ST_CollectionExtract(ST_Intersection(rw.geom, wl.geom), 1) AS geom 
INTO t2019_kar_bridges 
FROM t2019_kar_railways rw, t2019_kar_water_lines wl;

SELECT ST_AsText(geom) FROM t2019_kar_bridges
