/*
 * receptors
 * ---------
 * Table containing the receptors (standard calculation points).
 * Receptors represent the center point of the accompanying hexagons.
 */
CREATE TABLE receptors (
	receptor_id integer NOT NULL,
	geometry geometry(Point),

	CONSTRAINT receptors_pkey PRIMARY KEY (receptor_id)
);

CREATE INDEX idx_receptors_geometry_gist ON receptors USING GIST (geometry);


/*
 * hexagons
 * --------
 * Table containing the hexagons (including geometry) that belong to receptors.
 * These hexagons serve as a representation of the receptor at a certain zoom level.
 * For NL, the surface of a hexagon at zoom level 1 matches a hectare.
 * For UK, the surface of a hexagon at zoom level 1 matches 4 hectares.
 * At higher zoom levels the hexagons are aggregations.
 */
CREATE TABLE hexagons (
	receptor_id integer NOT NULL,
	zoom_level posint NOT NULL,
	geometry geometry(Polygon),

	CONSTRAINT hexagons_pkey PRIMARY KEY (receptor_id, zoom_level),
	CONSTRAINT hexagons_fkey_receptors FOREIGN KEY (receptor_id) REFERENCES receptors
);

CREATE INDEX idx_hexagons_geometry_gist ON hexagons USING GIST (geometry);
CREATE INDEX idx_hexagons_zoom_level ON hexagons (zoom_level);
