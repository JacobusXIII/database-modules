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
 * ae_create_square
 * ----------------
 * Create a square geometry based on a central point and the size of each edge.
 * Inspired by https://web.archive.org/web/20150504125339/http://dimensionaledge.com/intro-vector-tiling-map-reduce-postgis/
 */
CREATE OR REPLACE FUNCTION grid.ae_create_square(centerpoint geometry, side double precision)
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
 * ae_create_regular_grid
 * ----------------------
 * Create a standard grid based on a geometry, where each square in the grid has the same size (through side, the size of each edge).
 * Inspired by https://web.archive.org/web/20150504125339/http://dimensionaledge.com/intro-vector-tiling-map-reduce-postgis/
 */
CREATE OR REPLACE FUNCTION grid.ae_create_regular_grid(extent geometry, side double precision)
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
			RETURN QUERY SELECT ST_SnapToGrid(grid.ae_create_square(centerpoint, side), 0.000001);
		END LOOP;  -- after exiting the subloop, increment the y count and y value
		y_count := y_count + 1;
		y_value := y_value - side;
	END LOOP;
	RETURN;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE;
