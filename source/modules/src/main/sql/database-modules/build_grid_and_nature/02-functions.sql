/*
 * ae_get_calculator_grid_boundary_box
 * -----------------------------------
 * Function returning the bounding box for calculator, based on the CALCULATOR_GRID_BOUNDARY_BOX constant value.
 */
CREATE OR REPLACE FUNCTION grid.ae_get_calculator_grid_boundary_box()
	RETURNS Box2D AS
$BODY$
BEGIN
	RETURN Box2D(ST_GeomFromText(system.constant('CALCULATOR_GRID_BOUNDARY_BOX'), ae_get_srid()));
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;



/*
 * ae_determine_square
 * -------------------
 * Create a square geometry based on a central point and the size of each edge.
 * Inspired by https://web.archive.org/web/20150504125339/http://dimensionaledge.com/intro-vector-tiling-map-reduce-postgis/
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_square(centerpoint geometry, side double precision)
       RETURNS geometry AS
$BODY$
SELECT ST_SetSRID(ST_MakePolygon(ST_MakeLine(
       ARRAY[
               ST_MakePoint(ST_X(centerpoint) - 0.5 * side, ST_Y(centerpoint) + 0.5 * side),
               ST_MakePoint(ST_X(centerpoint) + 0.5 * side, ST_Y(centerpoint) + 0.5 * side),
               ST_MakePoint(ST_X(centerpoint) + 0.5 * side, ST_Y(centerpoint) - 0.5 * side),
               ST_MakePoint(ST_X(centerpoint) - 0.5 * side, ST_Y(centerpoint) - 0.5 * side),
               ST_MakePoint(ST_X(centerpoint) - 0.5 * side, ST_Y(centerpoint) + 0.5 * side)
               ]
       )), ST_SRID(centerpoint));
$BODY$
LANGUAGE sql IMMUTABLE STRICT;


/*
 * ae_determine_regular_grid
 * -------------------------
 * Create a standard grid based on a geometry, where each square in the grid has the same size (through side, the size of each edge).
 * Inspired by https://web.archive.org/web/20150504125339/http://dimensionaledge.com/intro-vector-tiling-map-reduce-postgis/
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_regular_grid(extent geometry, side double precision)
       RETURNS setof geometry AS
$BODY$
DECLARE
       x_min double precision;
       x_max double precision;
       y_min double precision;
       y_max double precision;
       x_value double precision;
       y_value double precision;
       x_count integer;
       y_count integer DEFAULT 1;
       srid integer;
       centerpoint geometry;
BEGIN
       srid := ST_SRID(extent);
       x_min := ST_XMin(extent);
       y_min := ST_YMin(extent);
       x_max := ST_XMax(extent);
       y_value := ST_YMax(extent);

       WHILE y_value  + 0.5 * side > y_min LOOP -- for each y value, reset x to x_min and subloop through the x values
               x_count := 1;
               x_value := x_min;
               WHILE x_value - 0.5 * side < x_max LOOP
                       centerpoint := ST_SetSRID(ST_MakePoint(x_value, y_value), srid);
                       x_count := x_count + 1;
                       x_value := x_value + side;
                       RETURN QUERY SELECT ST_SnapToGrid(ae_determine_square(centerpoint, side), 0.000001);
               END LOOP;  -- after exiting the subloop, increment the y count and y value
               y_count := y_count + 1;
               y_value := y_value - side;
       END LOOP;
       RETURN;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE;


/*
 * ae_determine_assessment_area_geometry_of_interest
 * -------------------------------------------------
 * Function returning the geometry of interest for an assessment area.
 * The geometry of interest is the geometry of the assessment area on land plus the geometry of the area where there are habitat areas.
 * To ensure everything is covered, a buffer is added for the section on water, and for the union of land and water sections this buffer is added as well.
 * For NL this buffer (as defined by a constant) is 170m.
 * For UK this buffer (as defined by a constant) is 850m.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_assessment_area_geometry_of_interest(v_assessment_area_id integer, v_land_geometry geometry)
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
				INNER JOIN nature.habitat_type_sensitivity_view USING (habitat_type_id)

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
 * ae_determine_hexagon_intersections
 * ----------------------------------
 * Function to determine the intersections of our hexagons (at zoom level 10 with a supplied geometry.
 * This is based on the hexagons in the hexagons table, not every possible hexagons imaginable.
 * Inspired by https://web.archive.org/web/20150504125339/http://dimensionaledge.com/intro-vector-tiling-map-reduce-postgis/.
 * @param v_geometry The geometry to determine intersects for.
 * @param v_gridsize The size of the used grids in kilometers.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_hexagon_intersections(v_geometry geometry(MultiPolygon), v_gridsize integer = 1)
	RETURNS TABLE(receptor_id integer, surface double precision, geometry geometry) AS
$BODY$
	WITH
	split_geometry AS (
		SELECT (ST_Dump(v_geometry)).geom AS geometry
	),
	regular_grid AS (
		SELECT grid.ae_determine_regular_grid(ST_Envelope(v_geometry), v_gridsize * 1000)::geometry(Polygon) AS geometry
	),
	intersected AS (
		SELECT
			CASE
				WHEN ST_Within(regular_grid.geometry, split_geometry.geometry)
				THEN regular_grid.geometry
				ELSE ST_Intersection(regular_grid.geometry, split_geometry.geometry) END AS geometry
			FROM regular_grid
				INNER JOIN split_geometry ON ST_Intersects(regular_grid.geometry, split_geometry.geometry) AND regular_grid.geometry && split_geometry.geometry
	),
	vector_tiles AS (
		SELECT (ST_Dump(intersected.geometry)).geom AS geometry	FROM intersected WHERE intersected.geometry IS NOT NULL
	),
	intersected_areas AS (
		SELECT
			hexagons.receptor_id,
			ST_Intersection(vector_tiles.geometry, hexagons.geometry) AS geometry

			FROM vector_tiles
				INNER JOIN grid.hexagons ON ST_Intersects(vector_tiles.geometry, hexagons.geometry)

			WHERE zoom_level = 1
	),
	unioned_intersected_areas AS (
		SELECT
			intersected_areas.receptor_id,
			ST_Union(intersected_areas.geometry) AS geometry

			FROM intersected_areas
			GROUP BY intersected_areas.receptor_id
	)
	SELECT
		unioned_intersected_areas.receptor_id,
		ST_Area(unioned_intersected_areas.geometry) AS surface,
		unioned_intersected_areas.geometry

		FROM unioned_intersected_areas

		WHERE ST_Area(unioned_intersected_areas.geometry) > 0;
$BODY$
LANGUAGE sql VOLATILE;


/*
 * ae_determine_habitat_coverage_on_hexagon
 * ----------------------------------------
 * Function to determine the average coverage for a critical deposition area on a receptor. This can be either a habitat or a relevant habitat.
 *
 * The coverages of the intersecting (relevant) habitat areas is retrieved, and these combined into a weighted average per habitat.
 * Weight is based on the surface of the intersection between habitat area and the hexagon at zoom levl 1.
 *
 * The multiplication of this intersection-surface and the average coverage results in the cartographic surface (gekarteerde oppervlakte) of the
 * critical deposition area on this receptor.
 * This will be the same as determining the individual cartographic surfaces per intersected habitat area and summing those values.
 *
 * @returns Average coveragefraction for a habitat on a receptor, weighted by surface of the intersections between habitat areas and hexagon.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_habitat_coverage_on_hexagon(v_assessment_area_id integer, v_type nature.critical_deposition_area_type, v_habitat_type_id integer, v_receptor_id integer)
	RETURNS fraction AS
$BODY$
	WITH hexagon AS (SELECT geometry FROM grid.hexagons WHERE receptor_id = v_receptor_id AND zoom_level = 1)
	SELECT
		system.weighted_avg(coverage::numeric, ST_Area(ST_Intersection(habitat_areas.geometry, hexagon.geometry))::numeric)::fraction

		FROM nature.habitat_areas
			CROSS JOIN hexagon

		WHERE assessment_area_id = v_assessment_area_id
			AND habitat_type_id = v_habitat_type_id
			AND ST_Intersects(habitat_areas.geometry, hexagon.geometry)
		HAVING v_type = 'habitat'
	UNION ALL
	SELECT
		system.weighted_avg(coverage::numeric, ST_Area(ST_Intersection(relevant_habitat_areas.geometry, hexagon.geometry))::numeric)::fraction

		FROM nature.relevant_habitat_areas
			CROSS JOIN hexagon

		WHERE assessment_area_id = v_assessment_area_id
			AND habitat_type_id = v_habitat_type_id
			AND ST_Intersects(relevant_habitat_areas.geometry, hexagon.geometry)
		HAVING v_type = 'relevant_habitat'
	;
$BODY$
LANGUAGE SQL STABLE;


/**
 * ae_determine_number_of_hexagon_rows
 * -----------------------------------
 * Function to determine the number of hexagons in a horizontal row.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_number_of_hexagon_rows(zoomlevel int = 1)
	RETURNS int AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box are declared
	bounding_box Box2D = grid.ae_get_calculator_grid_boundary_box();
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
 * ae_determine_coordinates_from_receptor_id
 * -----------------------------------------
 * Function to determine the coordinates (point geometry) for the supplied receptor_id.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_coordinates_from_receptor_id(receptor_id int)
       RETURNS geometry AS
$BODY$
DECLARE
       -- First the coordinates of the lower left and upper right corner of the bounding box are declared
       bounding_box Box2D = grid.ae_get_calculator_grid_boundary_box();
       coordinate_x_min int = ceiling(ST_XMin(bounding_box));
       coordinate_x_max int = floor(ST_XMax(bounding_box));
       coordinate_y_min int = ceiling(ST_YMin(bounding_box));
       coordinate_y_max int = floor(ST_YMax(bounding_box));

       -- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
       surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
       radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
       height_hexagon double precision = radius_hexagon * sqrt(3);
       number_of_hexagons_in_a_row int = grid.ae_determine_number_of_hexagon_rows();

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
 * ae_is_receptor_id_available_on_zoomlevel
 * ----------------------------------------
 * Function to determine if a receptor id is present on the supplied zoom level.
 */
CREATE OR REPLACE FUNCTION grid.ae_is_receptor_id_available_on_zoomlevel(receptor_id int, zoomlevel int)
	RETURNS bool AS
$BODY$
DECLARE
	-- First the coordinates of the lower left and upper right corner of the bounding box for hexagons are declared
	bounding_box Box2D = grid.ae_get_calculator_grid_boundary_box();
	coordinate_x_min int = ceiling(ST_XMin(bounding_box));
	coordinate_x_max int = floor(ST_XMax(bounding_box));
	coordinate_y_min int = ceiling(ST_YMin(bounding_box));
	coordinate_y_max int = floor(ST_YMax(bounding_box));

	-- Next the distance of the midpoint to a cornerpoint (radius) and the total height of the hexagon are given
	surface_zoom_level_1 int = system.constant('SURFACE_ZOOM_LEVEL_1')::integer;
	radius_hexagon double precision = |/(surface_zoom_level_1 * 2 / (3 * |/3));
	height_hexagon double precision = radius_hexagon * |/3;

	-- And the number of hexagons in a row
	number_of_hexagons_in_a_row int = grid.ae_determine_number_of_hexagon_rows();
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
 * ae_determine_hexagon
 * --------------------
 * Function to calculate and return a hexagon for the supplied receptor_id and zoom_level.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_hexagon(receptor_id posint, zoom_level posint)
	RETURNS geometry AS
$BODY$
DECLARE
--     _________
--    /c       b\         y3
--   /           \
--  /             \
--  \d          a /       y2
--   \           /
--    \e_______f/         y1
--
-- x1 x2      x3 x4
--
-- Polygon is (a,b,c,d,e,f,a)
--
	surface_zoom_level_1 integer;
	scaling_factor	posint;
	x_offset	double precision;
	y_offset	double precision;
	x1		text;
	x2		text;
	x3		text;
	x4		text;
	y1		text;
	y2		text;
	y3		text;
	a		text;
	b		text;
	c		text;
	d		text;
	e		text;
	f		text;
	hexagon 	geometry;
	hexagon_side_size	double precision;	-- the size of the side of the hexagon
	hexagon_width   	double precision;
	hexagon_height  	double precision;

BEGIN
	SELECT ST_X(ae_determine_coordinates_from_receptor_id), ST_Y(ae_determine_coordinates_from_receptor_id)
		INTO x_offset, y_offset
		FROM grid.ae_determine_coordinates_from_receptor_id(receptor_id);

	-- Initialise
	surface_zoom_level_1	= system.constant('SURFACE_ZOOM_LEVEL_1')::integer;

	scaling_factor		= 2^(zoom_level-1)::posint;
	hexagon_side_size	= sqrt((2/(3*sqrt(3)) * surface_zoom_level_1));
	hexagon_width 		= (hexagon_side_size * 2)::double precision;
	hexagon_height 		= (hexagon_side_size * sqrt(3))::double precision;
	x1			= (-hexagon_width/2)::text;
	x2			= (-hexagon_width/4)::text;
	x3			= (hexagon_width/4)::text;
	x4			= (hexagon_width/2)::text;
	y1			= (-hexagon_height/2)::text;
	y2			= 0::text;
	y3			= (hexagon_height/2)::text;

	-- Initialise points
	a		= x4 || ' ' || y2;
	b		= x3 || ' ' || y3;
	c		= x2 || ' ' || y3;
	d		= x1 || ' ' || y2;
	e		= x2 || ' ' || y1;
	f		= x3 || ' ' || y1;

	-- Create hexagon
	SELECT ('POLYGON((' || a || ',' || b || ',' || c || ',' || d || ',' || e || ',' || f || ',' || a || '))')::geometry INTO hexagon;

	-- Scale the hexagon and specify it using the correct SRID
	SELECT ST_Translate(ST_SetSRID(ST_Scale(hexagon, scaling_factor, scaling_factor), ae_get_srid()), x_offset, y_offset) INTO hexagon;
	RETURN hexagon;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;
