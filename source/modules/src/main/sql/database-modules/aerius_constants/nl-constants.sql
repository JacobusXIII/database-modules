/**
 * Default SRID.
 */
INSERT INTO system.constants (key, value) VALUES ('SRID', 28992);

/**
 * The geometry of interest area buffer (in meters).
 */
INSERT INTO system.constants (key, value) VALUES ('GEOMETRY_OF_INTEREST_BUFFER', 170);

/**
 * Number of zoom levels.
 */
INSERT INTO system.constants (key, value) VALUES ('MAX_ZOOM_LEVEL', 5);

/**
 * Surface of a zoom level 1 hexagon (in m^2)
 */
INSERT INTO system.constants (key, value) VALUES ('SURFACE_ZOOM_LEVEL_1', 10000);

/**
 * The boundary (box) for the calculation grid.
 */
INSERT INTO system.constants (key, value) VALUES ('CALCULATOR_GRID_BOUNDARY_BOX', 'POLYGON((3604 296800,3604 629300,287959 629300,287959 296800,3604 296800))');

/**
 * The zoom-levels for which deposition results are available.
 */
INSERT INTO system.constants (key, value) VALUES ('RESULT_ZOOM_LEVELS', '1');
