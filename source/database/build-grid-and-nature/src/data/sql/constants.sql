/**
 * Default SRID.
 */
INSERT INTO system.constants (key, value) VALUES ('SRID', 28992);

/**
 * The boundary (box) for the calculation grid.
 */
INSERT INTO system.constants (key, value) VALUES ('CALCULATOR_GRID_BOUNDARY_BOX', 'POLYGON((3604 296800,3604 629300,287959 629300,287959 296800,3604 296800))');

/**
 * The boundary of the calculation grid in Calculator. This is the inverse of the normal calculation boundary.
 */
INSERT INTO system.constants (key, value) VALUES ('CALCULATOR_BOUNDARY',
	'POLYGON(
		(-285804 22648,-285804 902914,595215 902914,595215 22648,-285804 22648),
		(141000 629000,100000 600000,80000 500000,3604 392000,3604 336000,101000 336000,161000 296800,219000 296800,287959 451000,287959 614000,259000 629000,141000 629000))');

/**
 * Surface of a zoom level 1 hexagon (in m^2)
 */
INSERT INTO system.constants (key, value) VALUES ('SURFACE_ZOOM_LEVEL_1', 10000);

/**
 * Number of zoom levels.
 */
INSERT INTO system.constants (key, value) VALUES ('MAX_ZOOM_LEVEL', 5);

/**
 * The geometry of interest area buffer (in meters).
 */
INSERT INTO system.constants (key, value) VALUES ('GEOMETRY_OF_INTEREST_BUFFER', 170);
