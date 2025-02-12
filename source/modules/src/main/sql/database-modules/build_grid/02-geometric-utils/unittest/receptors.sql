/*
 * ae_unittest_determine_receptor_id_from_coordinates_from_receptor_id
 * -------------------------------------------------------------------
 * Unittest function that:
 * - Creates a random receptor id within the range of all receptors.
 * - The coordinates for this receptor are determined.
 * - Then the ID is determined based on the coordinates
 * - The resulting ID should match the original ID used.
 * This is done 100 times.
 */
CREATE OR REPLACE FUNCTION grid.ae_unittest_determine_receptor_id_from_coordinates_from_receptor_id()
	RETURNS void AS
$BODY$
DECLARE
	-- Some dummy variables
	max_receptors int = 9462981;
	loop_iterator int = 0;
	random_receptor_id int;
	calculated_receptor_id int;
	geometry_from_function geometry;
BEGIN
	WHILE (loop_iterator < 100) LOOP
		random_receptor_id 	:= round(max_receptors * random())::int;
		geometry_from_function	:= grid.ae_determine_coordinates_from_receptor_id(random_receptor_id);
		calculated_receptor_id	:= grid.ae_determine_receptor_id_from_coordinates(round(ST_X(geometry_from_function))::int, round(ST_Y(geometry_from_function))::int,1);

		PERFORM system.assert_equals(random_receptor_id, calculated_receptor_id);

		loop_iterator = loop_iterator + 1;
	END LOOP;
END;
$BODY$
LANGUAGE plpgsql STABLE;


/*
 * ae_unittest_determine_receptor_ids_from_receptor_with_radius
 * ------------------------------------------------------------
 * Unittest function to determine if the ae_determine_receptor_ids_from_receptor_with_radius function gives valid results at the border of the bounding box.
 * When the borders are correctly incorporated, the vertical projection of the receptors shouldn't contain any 'holes' or 'gaps'.
 * This is done 100 times.
 */
CREATE OR REPLACE FUNCTION grid.ae_unittest_determine_receptor_ids_from_receptor_with_radius()
	RETURNS void AS
$BODY$
DECLARE
	-- Some dummy variables
	loop_iterator int = 0;

	max_receptor_id int = 9462980;
	max_radius int = 1529;

	receptor_id int;
	radius int;
	number_of_distinct_rows int;
	first_vertically_projected int;
	last_vertically_projected int;
BEGIN
	WHILE (loop_iterator < 100) LOOP

		receptor_id	:= 1 + (round(max_receptor_id * random()))::int;
		radius		:= 1 + (round(max_radius * random()))::int;
		-- The perpendicular projection of the receptor_ids is done by taking the distinct numbers modulo the number of hexagons horizontally.
		CREATE TEMPORARY TABLE tmp_calculated_receptor_ids AS SELECT DISTINCT ((receptor_id_calc - 1) % 1529 + 1) AS vert_proj
					FROM grid.ae_determine_receptor_ids_from_receptor_with_radius(receptor_id, radius) AS receptor_id_calc
					ORDER BY vert_proj ASC;
		number_of_distinct_rows 	:= count(*) FROM tmp_calculated_receptor_ids;
		first_vertically_projected 	:= vert_proj FROM tmp_calculated_receptor_ids ORDER BY vert_proj ASC LIMIT 1;
		last_vertically_projected 	:= vert_proj FROM tmp_calculated_receptor_ids ORDER BY vert_proj DESC LIMIT 1;

		-- Because the set in tmp_calculated_receptor_ids is an ordered and distinct set of integers, the following holds: id(x+n) >= id(x) + n.
		-- Furthermore when there are no "holes" in the set, the following holds: id(x+n) = id(x) + n. So we only need the first and last id in the set
		-- and the number of id's.
		PERFORM system.assert_equals(first_vertically_projected + number_of_distinct_rows - 1, last_vertically_projected, 'failed at receptor ' || receptor_id);

		DROP TABLE tmp_calculated_receptor_ids;

		loop_iterator = loop_iterator + 1;
	END LOOP;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_unittest_determine_receptor_id_from_coordinates
 * --------------------------------------------------
 * Unittest function that:
 * - Creates a random point within the bounding box.
 * - Determines the existing receptor according to postgis (using intersection of the point with the zoom level 1 hexagons)
 * - If this exists, the function 'ae_determine_receptor_id_from_coordinates' is used to determine receptor_id as well
 * - The resulting ID should match the ID of the zoom lvel 1 hexagon.
 * This is done 1000 times.
 */
CREATE OR REPLACE FUNCTION grid.ae_unittest_determine_receptor_id_from_coordinates()
	RETURNS void AS
$BODY$
DECLARE
	-- To know the bouderies of the x and y variable, the min and maximum of the bounding box are given:

	coordinate_x_min int = 0;
	coordinate_x_max int = 281000;
	coordinate_y_min int = 306000;
	coordinate_y_max int = 625000;

	-- Finally some dummy variables
	loop_iterator int = 0;
	no_loop_iterator int = 0;
	test_x_coordinate int;
	test_y_coordinate int;
	test_point geometry;
	receptor_id_in_database int;
	receptor_id_from_function int;
BEGIN
	WHILE (loop_iterator < 100) LOOP
		test_x_coordinate := round(coordinate_x_min + (coordinate_x_max - coordinate_x_min) * random())::int;
		test_y_coordinate := round(coordinate_y_min + (coordinate_y_max - coordinate_y_min) * random())::int;
		test_point := ST_SetSRID(ST_MakePoint(test_x_coordinate, test_y_coordinate), ae_get_srid());
		receptor_id_in_database := receptor_id FROM hexagons WHERE ST_Within(test_point, hexagons.geometry) AND zoom_level = 1;
		-- Only count when there are receptors in the database
		IF (receptor_id_in_database > 0) THEN
			receptor_id_from_function = grid.ae_determine_receptor_id_from_coordinates(test_x_coordinate, test_y_coordinate, 1);
			PERFORM system.assert_equals(receptor_id_in_database, receptor_id_from_function);
			no_loop_iterator = 0;
			loop_iterator = loop_iterator + 1;
		ELSE
			no_loop_iterator = no_loop_iterator + 1;
			PERFORM system.assert_true(no_loop_iterator <= 1000, 'no receptors found after 1000 random point attempts');
		END IF;
	END LOOP;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_unittest_determine_receptor_ids_in_rectangle
 * -----------------------------------------------
 * Unittest function that:
 * - Creates a random rectangle within the bounding box.
 * - Determines the receptors within the random rectangle by using the postgis within function on the existing receptors table.
 * - Then uses the function 'ae_determine_receptor_ids_in_rectangle' to determine receptors and joins those with the existing receptors table.
 * - The resulting lists should contain the same receptor_ids.
 * This is done 100 times.
 */
CREATE OR REPLACE FUNCTION grid.ae_unittest_determine_receptor_ids_in_rectangle()
	RETURNS void AS
$BODY$
DECLARE
	-- Some dummy variables
	coordinate_x_min int = 0;
	coordinate_x_max int = 281000;
	coordinate_y_min int = 306000;
	coordinate_y_max int = 625000;

	loop_iterator int = 0;
	x_min_for_rectangle int;
	x_max_for_rectangle int;
	y_min_for_rectangle int;
	y_max_for_rectangle int;

	point_low_left	geometry;
	point_up_right	geometry;
	rectangle	geometry;

	number_of_distinct_rows	int;
BEGIN
	WHILE (loop_iterator < 100) LOOP
		-- Get a random min and max X,Y coordinate and get the corresponding receptors according to postgis
		x_min_for_rectangle	:= coordinate_x_min + round((coordinate_x_max - coordinate_x_min) * random())::int;
		x_max_for_rectangle	:= x_min_for_rectangle + round((coordinate_x_max - x_min_for_rectangle) * random())::int;
		y_min_for_rectangle	:= coordinate_y_min + round((coordinate_y_max - coordinate_y_min) * random())::int;
		y_max_for_rectangle	:= y_min_for_rectangle + round((coordinate_y_max - y_min_for_rectangle) * random())::int;
		point_low_left		:= ST_MakePoint(x_min_for_rectangle,y_min_for_rectangle);
		point_up_right		:= ST_MakePoint(x_max_for_rectangle,y_max_for_rectangle);
		rectangle		:= ST_SetSRID(ST_MakeBox2D(point_low_left, point_up_right), ae_get_srid());
		CREATE TEMPORARY TABLE tmp_postgis_receptor_ids AS SELECT receptor_id FROM receptors WHERE ST_Within (receptors.geometry, rectangle);

		-- Get the receptors from the rectangle by the function. Get the intersection of these receptors and the receptors in the db. This intersection should be exactly the same the the receptors above, so there should be no distinct rows.
		CREATE TEMPORARY TABLE tmp_calculated_receptor_ids AS SELECT grid.ae_determine_receptor_ids_in_rectangle(x_min_for_rectangle, x_max_for_rectangle, y_min_for_rectangle, y_max_for_rectangle) AS receptor_id_calc;
		CREATE TEMPORARY TABLE tmp_intersect_receptor_ids AS SELECT receptor_id AS receptor_id_inner FROM tmp_calculated_receptor_ids INNER JOIN receptors ON (receptor_id_calc = receptor_id);
		CREATE TEMPORARY TABLE tmp_distinct_receptor_ids AS SELECT * FROM tmp_postgis_receptor_ids FULL OUTER JOIN tmp_intersect_receptor_ids ON (receptor_id = receptor_id_inner) WHERE receptor_id IS NULL OR receptor_id_inner IS NULL;
		number_of_distinct_rows = count(*) FROM tmp_distinct_receptor_ids;

		PERFORM system.assert_equals(0, number_of_distinct_rows, 'failed at iteration ' || loop_iterator);

		DROP TABLE tmp_postgis_receptor_ids;
		DROP TABLE tmp_calculated_receptor_ids;
		DROP TABLE tmp_intersect_receptor_ids;
		DROP TABLE tmp_distinct_receptor_ids;

		loop_iterator = loop_iterator + 1;
	END LOOP;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_unittest_is_receptor_id_available_on_zoomlevel
 * -------------------------------------------------
 * Unittest function that:
 * - Checks for 3 predetermined receptors, which are known to be present on zoom level 5, if they are available on zoom level 5 according to ae_is_receptor_id_available_on_zoomlevel.
 * - Determines 20 random receptor_ids from the hexagons table for zoom levels 1 through 5.
 * - Then checks if ae_is_receptor_id_available_on_zoomlevel indicates if these receptors are indeed present on the zoom level for which they were selected.
 */
CREATE OR REPLACE FUNCTION grid.ae_unittest_is_receptor_id_available_on_zoomlevel()
	RETURNS void AS
$BODY$
DECLARE
	-- Three receptors from which we know they are available on zoomlevel 5:
	input_1 int = 1;
	input_2 int = 33;
	input_3 int = 48929;

	-- Finally some dummy variables
	rec_id_test int;
	zoomlevel_test posint;
BEGIN
	--The first part of the test.
	PERFORM system.assert_true(grid.ae_is_receptor_id_available_on_zoomlevel(input_1, 5), 'failed at receptor ' || input_1 || ' zoomlevel 5');
	PERFORM system.assert_true(grid.ae_is_receptor_id_available_on_zoomlevel(input_2, 5), 'failed at receptor ' || input_2 || ' zoomlevel 5');
	PERFORM system.assert_true(grid.ae_is_receptor_id_available_on_zoomlevel(input_3, 5), 'failed at receptor ' || input_3 || ' zoomlevel 5');

	--The second part of the test. The geometry_test table has 100 records, so the succes_counter must also reach 100.
	CREATE TEMPORARY TABLE tmp_geometry_test ON COMMIT DROP AS SELECT receptor_id, zoom_level FROM hexagons WHERE zoom_level = 1 ORDER BY random() LIMIT 20;
	INSERT INTO tmp_geometry_test SELECT receptor_id, zoom_level FROM hexagons WHERE zoom_level = 2 ORDER BY random() LIMIT 20;
	INSERT INTO tmp_geometry_test SELECT receptor_id, zoom_level FROM hexagons WHERE zoom_level = 3 ORDER BY random() LIMIT 20;
	INSERT INTO tmp_geometry_test SELECT receptor_id, zoom_level FROM hexagons WHERE zoom_level = 4 ORDER BY random() LIMIT 20;
	INSERT INTO tmp_geometry_test SELECT receptor_id, zoom_level FROM hexagons WHERE zoom_level = 5 ORDER BY random() LIMIT 20;

	FOR rec_id_test IN SELECT receptor_id FROM tmp_geometry_test LOOP
		zoomlevel_test	:= zoom_level FROM tmp_geometry_test WHERE receptor_id = rec_id_test LIMIT 1;
		PERFORM system.assert_true(grid.ae_is_receptor_id_available_on_zoomlevel(rec_id_test, zoomlevel_test), 'failed at receptor ' || rec_id_test || ' zoomlevel ' || zoomlevel_test);
	END LOOP;

	DROP TABLE tmp_geometry_test;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


/*
 * ae_unittest_determine_coordinates_from_receptor_id
 * --------------------------------------------------
 * Unittest function that
 * - Determines a random receptor_id and geometry combination from the receptors table.
 * - Then checks if ae_determine_coordinates_from_receptor_id returns the same geometry based on the receptor_id.
 * This is done 100 times.
 */
CREATE OR REPLACE FUNCTION grid.ae_unittest_determine_coordinates_from_receptor_id()
	RETURNS void AS
$BODY$
DECLARE
	-- Some dummy variables
	loop_iterator int := 0;
	receptor_id_in_database int;
	geometry_in_database geometry;
BEGIN
	WHILE (loop_iterator < 100) LOOP
		receptor_id_in_database := receptor_id FROM nature.receptors ORDER BY random() LIMIT 1;
		geometry_in_database 	:= geometry FROM nature.receptors WHERE receptor_id = receptor_id_in_database;

		PERFORM system.assert_equals(geometry_in_database, grid.ae_determine_coordinates_from_receptor_id(receptor_id_in_database), 'failed at receptor ' || receptor_id_in_database);
		loop_iterator = loop_iterator + 1;
	END LOOP;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
