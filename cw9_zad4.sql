CREATE TABLE exports_union AS
SELECT ST_Union(rast) FROM exports

DROP TABLE exports