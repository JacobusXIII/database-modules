/*
 * ae_build_geometry_of_interests
 * ------------------------------
 * Function to determine (and fill) the geometry of interests for all assessment areas.
 * This function has to be run before creating receptors.
 */
CREATE OR REPLACE FUNCTION grid.ae_build_geometry_of_interests()
	RETURNS void AS
$BODY$
DECLARE
	v_land_geometry geometry;
BEGIN
	RAISE NOTICE '[%] Generating land geometry...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	v_land_geometry := (SELECT ST_Union(geometry) FROM grid.province_land_borders);

	RAISE NOTICE '[%] Generating all geometry of interests...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	INSERT INTO grid.geometry_of_interests(assessment_area_id, geometry)
	SELECT * FROM
		(SELECT
			assessment_area_id,
			ST_Multi(grid.ae_determine_assessment_area_geometry_of_interest(assessment_area_id, v_land_geometry)) AS geometry

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
 * ae_build_receptors
 * ------------------
 * Function to fill the receptor table with all receptors within geometries of interests of the assessment areas.
 * This function has to be run before hexagons can be created.
 */
CREATE OR REPLACE FUNCTION grid.ae_build_receptors()
	RETURNS void AS
$BODY$
DECLARE
	v_geometry_of_interests geometry;
	v_outside_boundary geometry;
BEGIN
	IF (SELECT COUNT(*) FROM grid.geometry_of_interests) = 0 THEN
		RAISE EXCEPTION '"grid.geometry_of_interests" table is empty. You must generate geometry of interests before receptors. You can use "grid.ae_build_geometry_of_interests()".';
	END IF;

	IF EXISTS(SELECT receptor_id FROM grid.hexagons LIMIT 1) THEN
		RAISE WARNING '"hexagons" table is not empty! You should generate receptors BEFORE hexagons!';
	END IF;

	RAISE NOTICE '[%] Merging geometry of interests...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	v_geometry_of_interests := (SELECT ST_Union(geometry) FROM grid.geometry_of_interests);

	RAISE NOTICE '[%] Subtracting outside boundary...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	v_outside_boundary := ST_SetSRID(ST_GeomFromText(system.constant('CALCULATOR_BOUNDARY')), ae_get_srid());
	v_geometry_of_interests := ST_Difference(v_geometry_of_interests, v_outside_boundary);

	RAISE NOTICE '[%] Generating receptors...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	CREATE TEMPORARY TABLE receptors_in_bb ON COMMIT DROP AS
	SELECT receptor_id, geometry FROM grid.ae_determine_receptor_ids_in_geometry(v_geometry_of_interests);

	RAISE NOTICE '[%] Inserting receptors...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
	INSERT INTO grid.receptors SELECT receptor_id, geometry FROM receptors_in_bb;

	DROP TABLE receptors_in_bb;

	RAISE NOTICE '[%] Done.', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_build_hexagons
 * -----------------
 * Function to fill the hexagons table with all hexagons belonging to the receptors.
 * This function should only be called after receptors have been created/inserted into the receptors table.
 */
CREATE OR REPLACE FUNCTION grid.ae_build_hexagons()
	RETURNS void AS
$BODY$
DECLARE
	v_max_zoom_level integer = system.constant('MAX_ZOOM_LEVEL')::integer;
	v_zoom_level integer;
BEGIN
	IF (SELECT COUNT(*) FROM grid.receptors) = 0 THEN
		RAISE EXCEPTION '"receptors" table is empty! You must generate receptors before hexagons. You can use "grid.ae_build_receptors()".';
	END IF;

	RAISE NOTICE '[%] Generating hexagons...', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');

	FOR v_zoom_level IN 1..v_max_zoom_level LOOP
		INSERT INTO grid.hexagons
		SELECT receptors.receptor_id, v_zoom_level, grid.ae_determine_hexagon(receptors.receptor_id, v_zoom_level)
			FROM grid.receptors
			WHERE
				v_zoom_level = 1
				OR grid.ae_is_receptor_id_available_on_zoomlevel(receptors.receptor_id, v_zoom_level);
	END LOOP;
	RAISE NOTICE '[%] Done.', to_char(clock_timestamp(), 'DD-MM-YYYY HH24:MI:SS.MS');
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
