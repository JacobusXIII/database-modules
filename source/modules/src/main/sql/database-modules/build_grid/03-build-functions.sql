/*
 * ae_assessment_area_geometry_of_interest
 * ---------------------------------------
 * Function returning the geometry of interest for an assessment area.
 * The geometry of interest is the geometry of the assessment area on land plus the geometry of the area where there are habitat areas.
 * To ensure everything is covered, a buffer is added for the section on water, and for the union of land and water sections this buffer is added as well.
 * For NL this buffer (as defined by a constant) is 170m.
 * For UK this buffer (as defined by a constant) is 850m.
 */
CREATE OR REPLACE FUNCTION ae_assessment_area_geometry_of_interest(v_assessment_area_id integer, v_land_geometry geometry)
	RETURNS geometry AS
$BODY$
DECLARE
	v_on_land_geometry geometry;
	v_on_water_geometry geometry;
	v_habitat_on_water_geometry geometry;
	v_habitat_on_water_count integer;
	v_buffer integer = system.constant('GEOMETRY_OF_INTEREST_BUFFER')::integer;
BEGIN
	-- Get the geometry of the assessment area on land and water
	v_on_land_geometry := (SELECT ST_Intersection(geometry, v_land_geometry) FROM nature.assessment_areas WHERE assessment_area_id = v_assessment_area_id);
	v_on_water_geometry := (SELECT ST_Difference(geometry, v_land_geometry) FROM nature.assessment_areas WHERE assessment_area_id = v_assessment_area_id);

	-- Habitat on land geometry must be set
	v_habitat_on_water_geometry := ST_GeomFromText('POLYGON EMPTY', ae_get_srid());

	-- Get the hatiat geometry on water
	IF (NOT ST_IsEmpty(v_on_water_geometry)) THEN
		-- Get the geometry of the habitat_areas within the on water geometry
		-- Use count because ST_Union(NULL) returns invalid geometry
		SELECT
			ST_Union(ST_Intersection(geometry, v_on_water_geometry)),
			COUNT(*)

			INTO v_habitat_on_water_geometry, v_habitat_on_water_count

			FROM nature.habitats
				INNER JOIN nature.habitat_type_critical_depositions_view USING (habitat_type_id)

			WHERE
				assessment_area_id = v_assessment_area_id
				AND sensitive IS TRUE
				AND ST_Intersects(v_on_water_geometry, geometry)
		;

		IF (v_habitat_on_water_count = 0) THEN
			v_habitat_on_water_geometry := ST_GeomFromText('POLYGON EMPTY', ae_get_srid());
		END IF;
	END IF;

	RAISE NOTICE E'Assessment area %: % m\u00B2 land, % m\u00B2 water, % m\u00B2 habitat on water.', v_assessment_area_id, FLOOR(ST_Area(v_on_land_geometry)), FLOOR(ST_Area(v_on_water_geometry)), FLOOR(ST_Area(v_habitat_on_water_geometry));

	RETURN ST_Buffer(ST_Union(v_on_land_geometry, ST_Buffer(v_habitat_on_water_geometry, 2 * v_buffer)), v_buffer);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_build_geometry_of_interests
 * ------------------------------
 * Function to determine (and fill) the geometry of interests for all assessment areas.
 * This function has to be run before creating receptors.
 */
CREATE OR REPLACE FUNCTION ae_build_geometry_of_interests()
	RETURNS void AS
$BODY$
DECLARE
	v_land_geometry geometry;
BEGIN
	RAISE NOTICE '[%] Generating land geometry...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	v_land_geometry := (SELECT ST_Union(geometry) FROM province_land_borders);

	RAISE NOTICE '[%] Generating all geometry of interests...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	INSERT INTO geometry_of_interests(assessment_area_id, geometry)
	SELECT * FROM
		(SELECT
			assessment_area_id,
			ST_Multi(ae_assessment_area_geometry_of_interest(assessment_area_id, v_land_geometry)) AS geometry

			FROM
				(SELECT assessment_area_id FROM nature.assessment_areas WHERE type = 'natura2000_area' ORDER BY assessment_area_id) AS assessment_area_ids
		)AS geometry_of_interest

		WHERE NOT ST_IsEmpty(geometry)
	;

	RAISE NOTICE '[%] Done.', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_build_hexagons_and_receptors
 * -------------------------------
 * Function to determine (and fill) the hexagons table with hexagons that intersects with the geometry of interests.
 * The recetors tabel is filled, based on the hexagons data, as well.
 */
CREATE OR REPLACE FUNCTION ae_build_hexagons_and_receptors()
	RETURNS void AS
$BODY$
DECLARE
	v_max_zoom_level integer = system.constant('MAX_ZOOM_LEVEL')::integer;
	v_zoom_level integer;
BEGIN

	RAISE NOTICE '[%] Generating hexagons and receptors...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');

	CREATE TEMPORARY TABLE tmp_hexagons (receptor_id integer NOT NULL, zoom_level posint NOT NULL, geometry geometry(Polygon), CONSTRAINT tmp_hexagons_pkey PRIMARY KEY (receptor_id, zoom_level)) ON COMMIT DROP;
	CREATE INDEX idx_tmp_hexagons_geometry_gist ON tmp_hexagons USING GIST (geometry);
	CREATE TEMPORARY TABLE tmp_receptors (receptor_id integer NOT NULL, geometry geometry(Point,28992), CONSTRAINT receptors_pkey PRIMARY KEY (receptor_id)) ON COMMIT DROP;
	CREATE INDEX idx_tmp_receptors_geometry_gist ON tmp_receptors USING GIST (geometry);

	WITH boundary AS (
	SELECT
		floor(ST_XMin(boundary))::int AS coordinate_x_left,
		ceiling(ST_XMax(boundary))::int AS coordinate_x_right,
		floor(ST_YMin(boundary))::int AS coordinate_y_lower,
		ceiling(ST_YMax(boundary))::int AS coordinate_y_upper

		FROM ae_get_calculator_grid_boundary_box() AS boundary
	), receptor_ids AS (
	SELECT 
		ae_determine_receptor_ids_in_rectangle(coordinate_x_left, coordinate_x_right, coordinate_y_lower, coordinate_y_upper) AS receptor_id

		FROM boundary
	)
	INSERT INTO tmp_receptors (receptor_id, geometry)
		SELECT receptor_id, ae_determine_coordinates_from_receptor_id(receptor_id) FROM receptor_ids;


	FOR v_zoom_level IN 1..v_max_zoom_level LOOP
		INSERT INTO tmp_hexagons
		SELECT receptor_id, v_zoom_level, ae_create_hexagon(receptor_id, v_zoom_level)
			FROM tmp_receptors
			WHERE
				v_zoom_level = 1
				OR ae_is_receptor_id_available_on_zoomlevel(receptor_id, v_zoom_level);
	END LOOP;

	ALTER TABLE hexagons
		DROP CONSTRAINT hexagons_fkey_receptors;

	-- first add all RESULT_ZOOM_LEVELS hexagons that intersect with the geometry of interest
	INSERT INTO hexagons
		SELECT DISTINCT receptor_id, zoom_level, tmp_hexagons.geometry
			FROM tmp_hexagons
				INNER JOIN geometry_of_interests ON ST_Intersects(tmp_hexagons.geometry, geometry_of_interests.geometry)
			WHERE zoom_level = ANY(string_to_array(system.constant('RESULT_ZOOM_LEVELS'), ',')::int[]);

	-- second add all non RESULT_ZOOM_LEVELS hexagons based on the receptor id's of the added RESULT_ZOOM_LEVELS hexagons
	INSERT INTO hexagons
		SELECT DISTINCT receptor_id, tmp_hexagons.zoom_level, tmp_hexagons.geometry
			FROM hexagons
				INNER JOIN tmp_hexagons USING (receptor_id)
			WHERE tmp_hexagons.zoom_level != ALL(string_to_array(system.constant('RESULT_ZOOM_LEVELS'), ',')::int[]);

	INSERT INTO receptors 
		SELECT DISTINCT receptor_id, tmp_receptors.geometry
			FROM tmp_receptors 
				INNER JOIN hexagons USING (receptor_id);

	ALTER TABLE hexagons
		ADD CONSTRAINT hexagons_fkey_receptors FOREIGN KEY (receptor_id) REFERENCES receptors;

	RAISE NOTICE '[%] Done.', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
