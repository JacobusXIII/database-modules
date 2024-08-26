/*
 * hexagon_type
 * ------------
 * The type of a hexagon, which is used for statistics of a calculation for example.
 */
CREATE TYPE grid.hexagon_type AS ENUM
	('relevant_hexagons', 'exceeding_hexagons', 'above_cl_hexagons');
