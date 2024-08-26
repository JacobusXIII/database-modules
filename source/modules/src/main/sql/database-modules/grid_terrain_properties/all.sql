/*
 * land_use_classification
 * -----------------------
 * The typ of classification for land use.
 */
CREATE TYPE grid.land_use_classification AS ENUM
	('grasland', 'bouwland', 'vaste gewassen', 'naaldbos', 'loofbos', 'water', 'bebouwing', 'overige natuur', 'kale grond');


/*
 * terrain_properties
 * ------------------
 * Table containing the average roughness and dominant land use per receptor and zoom level.
 * All values in this table are determined within the area of the hexagon at zoom level 1, corresponding to the receptor.
 * @column average_roughness The average roughness, in meters.
 * @column dominant_land_use The dominant land use, one of the values in land_use_classification enumeration.
 * @column land_uses The relative shares per receptor of each land use classification.
 * This is an array with 9 elements. The number 9 is equal to the number of values in the land_use_classification enum.
 */
CREATE TABLE grid.terrain_properties (
	receptor_id integer NOT NULL,
	zoom_level integer NOT NULL,
	average_roughness real NOT NULL,
	dominant_land_use grid.land_use_classification NOT NULL,
	land_uses integer ARRAY[9] NOT NULL,

	CONSTRAINT terrain_properties_pkey PRIMARY KEY (receptor_id, zoom_level)
);


/*
 * ae_integer_to_land_use_classification
 * -------------------------------------
 * Cast function for integer to land_use_classification.
 */
CREATE OR REPLACE FUNCTION grid.ae_integer_to_land_use_classification(anyint integer)
	RETURNS grid.land_use_classification AS
$BODY$
	SELECT system.enum_by_index(null::grid.land_use_classification, $1);
$BODY$
LANGUAGE sql IMMUTABLE;


/*
 * Cast definition for land_use_classification to integer
 */
CREATE CAST (grid.land_use_classification AS integer) WITH FUNCTION system.enum_to_index(anyenum);


/*
 * Cast definition for integer to land_use_classification
 */
CREATE CAST (integer AS grid.land_use_classification) WITH FUNCTION grid.ae_integer_to_land_use_classification(integer);
