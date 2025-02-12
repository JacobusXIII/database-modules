/*
 * ae_create_hexagon
 * -----------------
 * Function to calculate and return a hexagon for the supplied receptor_id and zoom_level.
 */
CREATE OR REPLACE FUNCTION grid.ae_create_hexagon(receptor_id posint, zoom_level posint)
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
