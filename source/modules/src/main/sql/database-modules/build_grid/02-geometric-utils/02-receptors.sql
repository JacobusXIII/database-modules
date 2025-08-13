/*
 * ae_determine_number_of_hexagon_rows
 * -----------------------------------
 * Function to determine the number of hexagons in a horizontal row.
 */
CREATE OR REPLACE FUNCTION ae_determine_number_of_hexagon_rows(zoomlevel int = 1)
	RETURNS int AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3)) * 2 ^ (zoomlevel - 1);
	height_hexagon double precision = radius_hexagon * |/3;

BEGIN
	-- And the number of hexagons in a row
	RETURN ceil( ( ceil((coordinate_x_max - coordinate_x_min) / (3.0 / 2 * radius_hexagon)) + 1 ) / 2 );
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_receptor_id_from_coordinates
 * -----------------------------------------
 * Function to determine the receptor_id for the supplied x, y coordinates and the zoom level.
 * Note! This function contains a bug and only works for zoom level 1.
 */
CREATE OR REPLACE FUNCTION ae_determine_receptor_id_from_coordinates(coordinate_x int, coordinate_y int, zoomlevel int)
	RETURNS int AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3)) * 2 ^ (zoomlevel - 1);
	height_hexagon double precision = radius_hexagon * |/3;

	-- And the number of hexagons in a row
	number_of_hexagons_in_a_row int = ae_determine_number_of_hexagon_rows(zoomLevel);

	-- Finally some dummy variables
	x_offset_even_rows int;
	x_offset_uneven_rows double precision;
	y_offset_even_rows int;
	y_offset_uneven_rows double precision;
	horizontal_distance_even_grid double precision;
	horizontal_distance_uneven_grid double precision;
	vertical_distance_even_grid double precision;
	vertical_distance_uneven_grid double precision;
	distance_even_grid double precision;
	distance_uneven_grid double precision;
	receptor_id int;
BEGIN
	-- Here the magic happens; see the document /doc/database/AERIUS_II_Geografische_Grid_Functies.docx for the calculation.
	x_offset_even_rows				:= coordinate_x - coordinate_x_min;
	x_offset_uneven_rows			:= x_offset_even_rows + 3 * radius_hexagon / 2;
	y_offset_even_rows				:= coordinate_y - coordinate_y_min;
	y_offset_uneven_rows			:= y_offset_even_rows + height_hexagon / 2;
	horizontal_distance_even_grid	:= x_offset_even_rows - trunc (x_offset_even_rows / (3 * radius_hexagon)) * 3 * radius_hexagon - 3.0 / 2 * radius_hexagon;
	horizontal_distance_uneven_grid	:= abs((x_offset_even_rows - 3.0 / 2 * radius_hexagon) - trunc ((x_offset_even_rows - 3.0 / 2 * radius_hexagon) / (3 * radius_hexagon))* 3 * radius_hexagon) - 3.0 / 2 * radius_hexagon;
	vertical_distance_even_grid		:= y_offset_even_rows - trunc (y_offset_even_rows / height_hexagon) * height_hexagon - height_hexagon / 2;
	vertical_distance_uneven_grid	:= abs((y_offset_even_rows - height_hexagon / 2) - trunc ((y_offset_even_rows - height_hexagon / 2) / height_hexagon) * height_hexagon) - height_hexagon / 2;
	distance_even_grid				:= horizontal_distance_even_grid ^ 2 + vertical_distance_even_grid ^ 2;
	distance_uneven_grid			:= horizontal_distance_uneven_grid ^ 2 + vertical_distance_uneven_grid ^ 2;

	IF distance_even_grid < distance_uneven_grid THEN
		receptor_id := (number_of_hexagons_in_a_row * (2 * trunc (y_offset_even_rows / height_hexagon) + 1) + trunc (x_offset_even_rows / (3 * radius_hexagon)) + 1);
	ELSE
		receptor_id := (number_of_hexagons_in_a_row * (2 * trunc (y_offset_uneven_rows / height_hexagon)) + trunc (x_offset_uneven_rows / (3 * radius_hexagon))) + 1;
	END IF;

	RETURN receptor_id;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_receptor_ids_in_rectangle
 * --------------------------------------
 * Function to determine the receptor_ids for the supplied rectangle (for example a background cell).
 */
CREATE OR REPLACE FUNCTION ae_determine_receptor_ids_in_rectangle(coordinate_x_left int, coordinate_x_right int, coordinate_y_lower int, coordinate_y_upper int)
	RETURNS SETOF int AS
$BODY$

DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box for hexagons are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	working_coordinate_x_left int = coordinate_x_left;
	working_coordinate_x_right int = coordinate_x_right;
	working_coordinate_y_lower int = coordinate_y_lower;
	working_coordinate_y_upper int = coordinate_y_upper;

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
	height_hexagon double precision = radius_hexagon * |/3;

	-- And the number of hexagons in a row
	number_of_hexagons_in_a_row int = ae_determine_number_of_hexagon_rows();

	-- Finally some dummy variables
	number_of_hex_before_rectangle_odd int;
	number_of_hex_hor_in_rectangle_odd int;
	number_of_hex_under_rectangle_odd  int;
	number_of_hex_ver_in_rectangle_odd int;
	number_of_hex_before_rectangle_even int;
	number_of_hex_hor_in_rectangle_even int;
	number_of_hex_under_rectangle_even  int;
	number_of_hex_ver_in_rectangle_even int;
	last_outside_receptor_id_odd int;
	last_outside_receptor_id_even int;
	return_receptor_id int;

BEGIN


	IF (coordinate_x_left >= coordinate_x_min)  THEN working_coordinate_x_left = coordinate_x_left;   ELSE working_coordinate_x_left = coordinate_x_min;  END IF;
	IF (coordinate_x_right <= coordinate_x_max) THEN working_coordinate_x_right = coordinate_x_right; ELSE working_coordinate_x_right = coordinate_x_max; END IF;
	IF (coordinate_y_lower >= coordinate_y_min) THEN working_coordinate_y_lower = coordinate_y_lower; ELSE working_coordinate_y_lower = coordinate_y_min; END IF;
	IF (coordinate_y_upper <= coordinate_y_max) THEN working_coordinate_y_upper = coordinate_y_upper; ELSE working_coordinate_y_upper = coordinate_y_max; END IF;

	IF (working_coordinate_x_left > coordinate_x_max
			OR working_coordinate_x_right < coordinate_x_min
			OR working_coordinate_y_lower > coordinate_y_max
			OR working_coordinate_y_upper < coordinate_y_min)
	THEN
		return_receptor_id = NULL;
		RETURN NEXT return_receptor_id;
	ELSE
		-- Here the magic happens, first for the odd rows of hexagons.
		number_of_hex_before_rectangle_odd := ceil((working_coordinate_x_left - coordinate_x_min) / (3 * radius_hexagon));
		number_of_hex_hor_in_rectangle_odd := ceil((working_coordinate_x_right - coordinate_x_min) / (3 * radius_hexagon)) - number_of_hex_before_rectangle_odd;
		number_of_hex_under_rectangle_odd  := ceil((working_coordinate_y_lower - coordinate_y_min) / height_hexagon);
		number_of_hex_ver_in_rectangle_odd := ceil((working_coordinate_y_upper - coordinate_y_min) / height_hexagon) - number_of_hex_under_rectangle_odd;
		last_outside_receptor_id_odd 	   := 2 * number_of_hex_under_rectangle_odd * number_of_hexagons_in_a_row + number_of_hex_before_rectangle_odd;

		FOR i IN 1..number_of_hex_ver_in_rectangle_odd LOOP
			FOR j IN 1..number_of_hex_hor_in_rectangle_odd LOOP
				return_receptor_id := last_outside_receptor_id_odd + j + 2 * (i - 1) * number_of_hexagons_in_a_row;
				RETURN NEXT return_receptor_id;
			END LOOP;
		END LOOP;

		-- And for the even rows of hexagons.
		number_of_hex_before_rectangle_even := trunc ((working_coordinate_x_left - coordinate_x_min + 1.5 * radius_hexagon) / (3 * radius_hexagon));
		number_of_hex_hor_in_rectangle_even := trunc ((working_coordinate_x_right - coordinate_x_min + 1.5 * radius_hexagon) / (3 * radius_hexagon)) - number_of_hex_before_rectangle_even;
		number_of_hex_under_rectangle_even  := trunc ((working_coordinate_y_lower - coordinate_y_min + 0.5 * height_hexagon) / height_hexagon);
		number_of_hex_ver_in_rectangle_even := trunc ((working_coordinate_y_upper - coordinate_y_min + 0.5 * height_hexagon) / height_hexagon) - number_of_hex_under_rectangle_even;
		last_outside_receptor_id_even 	    := (2 * number_of_hex_under_rectangle_even + 1) * number_of_hexagons_in_a_row + number_of_hex_before_rectangle_even;

		FOR i IN 1..number_of_hex_ver_in_rectangle_even LOOP
			FOR j IN 1..number_of_hex_hor_in_rectangle_even LOOP
				return_receptor_id := last_outside_receptor_id_even + j + 2 * (i - 1) * number_of_hexagons_in_a_row;
				RETURN NEXT return_receptor_id;
			END LOOP;
		END LOOP;

	END IF;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_receptor_ids_in_geometry
 * -------------------------------------
 * Function to determine the receptor_ids in the supplied geometry.
 * This is done by first determining all receptors in the bounding box, and then checking for each of these points that the point intersects with the geometry.
 */
CREATE OR REPLACE FUNCTION ae_determine_receptor_ids_in_geometry(v_geometry geometry)
	RETURNS TABLE(receptor_id int, geometry geometry) AS
$BODY$
DECLARE
	r_receptor_id int;
	r_geometry geometry;
BEGIN
	FOR r_receptor_id IN
		SELECT ae_determine_receptor_ids_in_rectangle(ST_XMin(v_geometry)::int, ST_XMax(v_geometry)::int, ST_YMin(v_geometry)::int, ST_YMax(v_geometry)::int)
	LOOP
		r_geometry := ae_determine_coordinates_from_receptor_id(r_receptor_id);
		IF ST_Intersects(r_geometry, v_geometry) THEN
			RETURN QUERY SELECT r_receptor_id, r_geometry;
		END IF;
	END LOOP;
	RETURN;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_receptor_ids_from_receptor_with_radius
 * ---------------------------------------------------
 * Function for determining receptor_ids that are within the supplied distance (the radius) of the supplied receptor.
 */
CREATE OR REPLACE FUNCTION ae_determine_receptor_ids_from_receptor_with_radius(receptor_id int, radius int)
	RETURNS SETOF int AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box for hexagons are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
	height_hexagon double precision = radius_hexagon * |/3;

	-- And the number of hexagons in a row
	number_of_hexagons_in_a_row int = ae_determine_number_of_hexagon_rows();
	number_of_hexagon_rows int = ceil( ((coordinate_y_max - coordinate_y_min) / height_hexagon) * 2 );
	receptor_id_max int = number_of_hexagons_in_a_row * number_of_hexagon_rows;

	-- Finally some dummy variables
	from_left int;
	to_right int;
	return_receptor_id int[];

BEGIN
	-- Here the magic happens.
	from_left = (receptor_id - 1) % number_of_hexagons_in_a_row + 1;
	to_right = number_of_hexagons_in_a_row - from_left + 1;

	IF (radius = 0) THEN
		RETURN NEXT receptor_id;
	ELSIF ((receptor_id - 1) / (number_of_hexagons_in_a_row ) % 2 = 0) THEN
		FOR t IN 0..(radius-1) LOOP
			return_receptor_id [1] = receptor_id + (2 * radius - t) * number_of_hexagons_in_a_row - ceil(t / 2.0);
			return_receptor_id [2] = receptor_id + (radius - 2 * t) * number_of_hexagons_in_a_row - ceil(radius / 2.0);
			return_receptor_id [3] = receptor_id - (radius + t)     * number_of_hexagons_in_a_row - ceil((radius - t) / 2.0);
			return_receptor_id [4] = receptor_id - (2 * radius - t) * number_of_hexagons_in_a_row + floor(t / 2.0);
			return_receptor_id [5] = receptor_id - (radius - 2 * t) * number_of_hexagons_in_a_row + floor(radius / 2.0);
			return_receptor_id [6] = receptor_id + (radius + t)     * number_of_hexagons_in_a_row + floor((radius - t) / 2.0);

			FOR i IN 1..6 LOOP
				IF (return_receptor_id[i] >= 0 AND return_receptor_id[i] <= receptor_id_max) THEN
					IF (i = 1) 	THEN IF (ceil(t / 2.0) < from_left) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 2)	THEN IF (ceil(radius / 2.0) < from_left) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 3) 	THEN IF (ceil((radius - t) / 2.0) < from_left) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 4) 	THEN IF (floor(t / 2.0) < to_right) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 5) 	THEN IF (floor(radius / 2.0) < to_right) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 6) 	THEN IF (floor((radius - t) / 2.0) < to_right) THEN RETURN NEXT return_receptor_id[i]; END IF;
					END IF;
				END IF;
			END LOOP;
		END LOOP;
	ELSE
		FOR t IN 0..(radius-1) LOOP
			return_receptor_id [1] = receptor_id + (2 * radius - t) * number_of_hexagons_in_a_row - floor(t / 2.0);
			return_receptor_id [2] = receptor_id + (radius - 2 * t) * number_of_hexagons_in_a_row - floor(radius / 2.0);
			return_receptor_id [3] = receptor_id - (radius + t)     * number_of_hexagons_in_a_row - floor((radius - t) / 2.0);
			return_receptor_id [4] = receptor_id - (2 * radius - t) * number_of_hexagons_in_a_row + ceil(t / 2.0);
			return_receptor_id [5] = receptor_id - (radius - 2 * t) * number_of_hexagons_in_a_row + ceil(radius / 2.0);
			return_receptor_id [6] = receptor_id + (radius + t)     * number_of_hexagons_in_a_row + ceil((radius - t) / 2.0);

			FOR i IN 1..6 LOOP
				IF (return_receptor_id[i] >= 0 AND return_receptor_id[i] <= receptor_id_max) THEN
					IF (i = 1) 	THEN IF (floor(t / 2.0) < from_left) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 2)	THEN IF (floor(radius / 2.0) < from_left) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 3) 	THEN IF (floor((radius - t) / 2.0) < from_left) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 4) 	THEN IF (ceil(t / 2.0) < to_right) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 5) 	THEN IF (ceil(radius / 2.0) < to_right) THEN RETURN NEXT return_receptor_id[i]; END IF;
					ELSIF (i = 6) 	THEN IF (ceil((radius - t) / 2.0) < to_right) THEN RETURN NEXT return_receptor_id[i]; END IF;
					END IF;
				END IF;
			END LOOP;
		END LOOP;
	END IF;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_is_receptor_id_available_on_zoomlevel
 * ----------------------------------------
 * Function to determine if a receptor id is present on the supplied zoom level.
 */
CREATE OR REPLACE FUNCTION ae_is_receptor_id_available_on_zoomlevel(receptor_id int, zoomlevel int)
	RETURNS bool AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box for hexagons are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
	height_hexagon double precision = radius_hexagon * |/3;

	-- And the number of hexagons in a row
	number_of_hexagons_in_a_row int = ae_determine_number_of_hexagon_rows();
	number_of_hexagon_rows int = ceil( ((coordinate_y_max - coordinate_y_min) / height_hexagon) * 2 );

	-- First the min and max receptor_ids and zoomlevel
	receptor_id_min 			int = 1;
	receptor_id_max 			int = number_of_hexagons_in_a_row * number_of_hexagon_rows;
	zoomlevel_min 				int = 1;
	zoomlevel_max 				int = 10;

	-- Some helper variables
	zoomlevel_factor			int = 2 ^ zoomlevel;
	zoomlevel_factor_minus_one	int = 2 ^ (zoomlevel - 1);

	-- Finally some dummy variables
	row_number			int;
	number_in_row		int;
	receptor_available 	boolean = false;

BEGIN
	IF (zoomlevel >= zoomlevel_min AND zoomlevel <= zoomlevel_max AND receptor_id >= receptor_id_min AND receptor_id <= receptor_id_max) THEN
		row_number = (receptor_id - 1) / number_of_hexagons_in_a_row;
		number_in_row = receptor_id - row_number * number_of_hexagons_in_a_row;
		IF (row_number % zoomlevel_factor = 0) THEN
			-- One of the rows where the numbering starts at the beginning
			IF ((number_in_row - 1) % zoomlevel_factor_minus_one = 0) THEN
				receptor_available = true;
			END IF;
		ELSIF (row_number % zoomlevel_factor = zoomlevel_factor_minus_one) THEN
			-- One of the rows where the numbering starts one step to the right
			IF ((number_in_row + zoomlevel_factor_minus_one / 2 - 1) % zoomlevel_factor_minus_one = 0) THEN
				receptor_available = true;
			END IF;
		END IF;
	END IF;

	RETURN receptor_available;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_coordinates_from_receptor_id
 * -----------------------------------------
 * Function to determine the coordinates (point geometry) for the supplied receptor_id.
 */
CREATE OR REPLACE FUNCTION ae_determine_coordinates_from_receptor_id(receptor_id int)
	RETURNS geometry AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
	height_hexagon double precision = radius_hexagon * sqrt(3);
	number_of_hexagons_in_a_row int = ae_determine_number_of_hexagon_rows();

	-- And finally the return variables
	return_coordinates double precision [];

BEGIN
	return_coordinates[0] = coordinate_x_min + ((receptor_id - 1) % number_of_hexagons_in_a_row) * 3 * radius_hexagon + (((receptor_id - 1) / number_of_hexagons_in_a_row) % 2) * 3 / 2.0 * radius_hexagon;
	return_coordinates[1] = coordinate_y_min + ((receptor_id - 1) / number_of_hexagons_in_a_row) * height_hexagon / 2.0;

	RETURN ST_SetSRID(ST_MakePoint(return_coordinates[0], return_coordinates[1]), ae_get_srid());
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_radius_and_offset_of_outer_receptor_from_midpoint_receptor
 * -----------------------------------------------------------------------
 * Function to determine the radius and number on this radius of a receptor (the outer receptor) with respect to another receptor (the midpoint receptor).
 */
CREATE OR REPLACE FUNCTION ae_determine_radius_and_offset_of_outer_receptor_from_midpoint_receptor(midpoint_receptor_id int, outer_receptor_id int, zoomlevel int = 1)
	RETURNS int [] AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box for hexagons are declared
	bounding_box Box2D = ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
	height_hexagon double precision = radius_hexagon * |/3;

	-- And the number of hexagons in a row
	number_of_hexagons_in_a_row int = ae_determine_number_of_hexagon_rows();

	-- Finally some dummy variables
	row_midpoint_receptor int;
	row_outer_receptor int;
	nr_on_row_midpoint_receptor int;
	nr_on_row_outer_receptor int;
	var_row_difference int;
	var_column_difference int;

	return_radius int;
	return_offset int;
	result int[];

BEGIN
	row_midpoint_receptor		:= (midpoint_receptor_id - 1) / number_of_hexagons_in_a_row + 1;
	row_outer_receptor		:= (outer_receptor_id - 1) / number_of_hexagons_in_a_row + 1;
	nr_on_row_midpoint_receptor 	:= (midpoint_receptor_id - 1) % number_of_hexagons_in_a_row + 1;
	nr_on_row_outer_receptor	:= (outer_receptor_id - 1) % number_of_hexagons_in_a_row + 1;
	var_row_difference		:= row_outer_receptor - row_midpoint_receptor;


	IF (midpoint_receptor_id = outer_receptor_id) THEN
		return_radius = 0;
		return_offset = 0;
	ELSE
		-- The variable n (var_column_difference) is different on an even or odd rows, so start by determine whether receptor_1 is on an even or odd row
		IF (row_midpoint_receptor % 2 = 0) THEN
			var_column_difference := 2 * (nr_on_row_outer_receptor - nr_on_row_midpoint_receptor) - abs(var_row_difference) % 2;
		ELSE
			var_column_difference := 2 * (nr_on_row_outer_receptor - nr_on_row_midpoint_receptor) + abs(var_row_difference) % 2;
		END IF;

		-- The radius depends on the absolute value of var_column_difference and var_row_difference
		IF (abs(var_column_difference) > abs(var_row_difference)) THEN
			return_radius := abs(var_column_difference);
		ELSE
			return_radius := (abs(var_column_difference) + abs(var_row_difference)) / 2;
		END IF;

		return_offset := row_number FROM (
					SELECT receptor_id_intern, row_number() over ()
						FROM ae_determine_receptor_ids_from_receptor_with_radius(midpoint_receptor_id, return_radius) AS receptor_id_intern
						WHERE ae_is_receptor_id_available_on_zoomlevel(receptor_id_intern, zoomlevel)
				) AS row_selection
				WHERE receptor_id_intern = outer_receptor_id;
	END IF;

	result[1] = return_radius;
	result[2] = return_offset;
	RETURN result;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;
