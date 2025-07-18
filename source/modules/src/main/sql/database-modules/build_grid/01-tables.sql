/*
 * province_land_borders
 * ---------------------
 * Table containing provincial land borders (excluding water).
 */
CREATE TABLE province_land_borders (
	province_land_border_id integer NOT NULL,
	name text NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT province_land_borders_pkey PRIMARY KEY (province_land_border_id),
	CONSTRAINT province_land_borders_name_unique UNIQUE (name)
);

CREATE INDEX province_land_borders_geometry_gist ON province_land_borders USING GIST (geometry);


/*
 * geometry_of_interests
 * ---------------------
 * Table containing the geometry of interest per assessment area.
 * Based on these geometries the receptors are created.
 */
CREATE TABLE geometry_of_interests (
	assessment_area_id integer NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT geometry_of_interests_pkey PRIMARY KEY (assessment_area_id)
);

CREATE INDEX geometry_of_interests_geometry_gist ON geometry_of_interests USING GIST (geometry);
