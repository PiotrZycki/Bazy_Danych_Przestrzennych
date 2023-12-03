--2
--raster2pgsql.exe -s 27700 -N -32767 -t 500x500 -I -C -M -d "D:\Studia\Semestr V\bazy\cw8\ras250_gb\data/*.tif" uk_250k | psql.exe -d cw8 -h localhost -U postgres -p 5432

--5
--ogr2ogr -f PostgreSQL "PG:user=postgres password=zaq1@WSX dbname=cw8" "D:\Studia\Semestr V\bazy\cw8\OS_Open_Zoomstack.gpkg" national_parks

--6
CREATE TABLE uk_lake_district 
AS
	SELECT ST_Clip(uk.rast, np.geom, TRUE) AS rast
	FROM uk_250k uk, national_parks np
	WHERE ST_Intersects(uk.rast, np.geom) AND np.id=1;

CREATE INDEX idx_ukld_rast_gist ON uk_lake_district
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('public'::name,
'uk_lake_district'::name,'rast'::name);

/*
CREATE TABLE uk_lake_district1
AS
	SELECT ST_Clip(uk.rast, np.geom, TRUE)
	FROM uk_250k uk, national_parks np
	WHERE (uk.rast && np.geom) AND np.id=1
SELECT * FROM uk_lake_district1

DROP TABLE uk_lake_district1
*/

--7
CREATE TABLE tmp_out 
AS
	SELECT lo_from_bytea
	(
		0,
		ST_AsGDALRaster
		( 
			ST_Union(rast), 
			'GTiff', 
			ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9']
		)
	)
	AS loid
	FROM uk_lake_district

SELECT lo_export(loid, 'D:\uk_lake_district.tiff')
FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out

--9
--raster2pgsql.exe -s 4326 -N -32767 -t 2500x1642 -I -C -M -d "D:\Studia\Semestr V\bazy\cw8\sentinel-2\Sentinel-2_L2A_B03.tiff" sentinel_b03 | psql.exe -d cw8 -h localhost -U postgres -p 5432
--raster2pgsql.exe -s 4326 -N -32767 -t 2500x1642 -I -C -M -d "D:\Studia\Semestr V\bazy\cw8\sentinel-2\Sentinel-2_L2A_B08.tiff" sentinel_b08 | psql.exe -d cw8 -h localhost -U postgres -p 5432

--10
CREATE TABLE green AS
	SELECT 1 AS id, ST_Union(rast) AS rast FROM sentinel_b03;

CREATE TABLE nir AS
	SELECT 1 AS id, ST_Union(rast) AS rast FROM sentinel_b08;

DROP TABLE nir1

CREATE TABLE ndwi AS
	WITH a AS (
		SELECT g.id, ST_Clip(g.rast, ST_Transform(np.geom, 4326), true) AS rast
		FROM green g, national_parks np
		WHERE ST_Intersects(ST_Transform(np.geom, 4326),g.rast) AND np.id=1
	),
	b AS (
		SELECT n.id, ST_Clip(n.rast, ST_Transform(np.geom, 4326), true) AS rast
		FROM nir n, national_parks np
		WHERE ST_Intersects(ST_Transform(np.geom, 4326),n.rast) AND np.id=1
	)
	SELECT
		a.id, 
		ST_MapAlgebra
		(
			a.rast,
			b.rast,
			'([rast1.val] - [rast2.val]) / ([rast1.val] +
			[rast2.val])::float','32BF'
		) AS rast
	FROM a, b;

CREATE INDEX idx_ndwi_rast_gist ON ndwi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('public'::name,
'ndwi'::name,'rast'::name);


--11
CREATE TABLE tmp_out 
AS
	SELECT lo_from_bytea
	(
		0,
		ST_AsGDALRaster
		( 
			ST_Union(rast), 
			'GTiff', 
			ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9']
		)
	)
	AS loid
	FROM ndwi;

SELECT lo_export(loid, 'D:\uk_lake_district_ndwi.tiff')
FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out
