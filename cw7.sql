--Ladowanie wysokosci
--1
--raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d D:\Studia\Semestr_V\bazy\cw7\Dane\srtm_1arc_v3.tif rasters.dem > D:\Studia\Semestr_V\bazy\cw7\Dane\dem.sql

--2
--raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d D:\Studia\Semestr_V\bazy\cw7\Dane\srtm_1arc_v3.tif rasters.dem | psql -d rastry -h localhost -U postgres -p 5432

--3
--raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d D:\Studia\Semestr_V\bazy\cw7\Dane\Landsat8_L1TP_RGBN.tif rasters.landsat8 | psql -d rastry -h localhost -U postgres -p 5432

SELECT * FROM  public.raster_columns


--Tworzenie rastrow z istniejących rastriw i interakcja z wektorami
--1
CREATE TABLE zycki.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

ALTER TABLE zycki.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON zycki.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('zycki'::name,'intersects'::name,'rast'::name);

--2
CREATE TABLE zycki.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--3
CREATE TABLE zycki.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


--Tworzenie rastrow z wektorow
--1
CREATE TABLE zycki.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--2
DROP TABLE zycki.porto_parishes; --> drop table porto_parishes first
CREATE TABLE zycki.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--3
DROP TABLE zycki.porto_parishes; --> drop table porto_parishes first
CREATE TABLE zycki.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1 
)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Konwertowanie rastrow na wektory
--1
CREATE TABLE zycki.intersection as
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--2
CREATE TABLE zycki.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Analiza rastrów
--1
CREATE TABLE zycki.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--2
CREATE TABLE zycki.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--3
CREATE TABLE zycki.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM zycki.paranhos_dem AS a;

--4
CREATE TABLE zycki.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM zycki.paranhos_slope AS a;

--5
SELECT st_summarystats(a.rast) AS stats
FROM zycki.paranhos_dem AS a;

--6
SELECT st_summarystats(ST_Union(a.rast))
FROM zycki.paranhos_dem AS a;

--7
WITH t AS (
	SELECT st_summarystats(ST_Union(a.rast)) AS stats
	FROM zycki.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--8
WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--9
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--10
CREATE TABLE zycki.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON zycki.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('zycki'::name,'tpi30'::name,'rast'::name);

--ZADANIE
CREATE TABLE zycki.tpi30_porto AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

CREATE INDEX idx_tpi30_porto_rast_gist ON zycki.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('zycki'::name,
'tpi30_porto'::name,'rast'::name);

--Algebra map
--1
CREATE TABLE zycki.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] +[rast1.val])::float','32BF'
	) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON zycki.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('zycki'::name,
'porto_ndvi'::name,'rast'::name);

--2
CREATE OR REPLACE FUNCTION zycki.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE zycki.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ILIKE 'porto' AND ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, ARRAY[1,4],
		'zycki.ndvi(double precision[],
		integer[],text[])'::regprocedure, --> This is the function!
			'32BF'::text
	) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON zycki.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('zycki'::name,'porto_ndvi2'::name,'rast'::name);

--Eksport danych
--1
SELECT ST_AsTiff(ST_Union(rast))
FROM zycki.porto_ndvi;

--2
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM zycki.porto_ndvi;

--SELECT ST_GDALDrivers();

--3
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(
	0,
	ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM zycki.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

DROP TABLE tmp_out

--4
--gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 
--PG:"host=localhost port=5432 dbname=rastry user=postgres 
--password=zaq1@WSX schema=zycki table=porto_ndvi mode=2" 
--porto_ndvi.tiff

