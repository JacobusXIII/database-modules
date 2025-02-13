/*
 * ae_determine_hexagon_intersections
 * ----------------------------------
 * Function to determine the intersections of our hexagons with a supplied geometry.
 * This is based on the hexagons in the hexagons table, not every possible hexagons imaginable.
 * Inspired by https://web.archive.org/web/20150504125339/http://dimensionaledge.com/intro-vector-tiling-map-reduce-postgis/.
 * @param v_geometry The geometry to determine intersects for.
 * @param v_gridsize The size of the used grids in kilometers.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_hexagon_intersections(v_geometry geometry(MultiPolygon), v_gridsize integer = 1)
	RETURNS TABLE(receptor_id integer, surface double precision, geometry geometry, zoom_level smallint) AS
$BODY$
	WITH
	split_geometry AS (
		SELECT (ST_Dump(v_geometry)).geom AS geometry
	),
	regular_grid AS (
		SELECT grid.ae_create_regular_grid(ST_Envelope(v_geometry), v_gridsize * 1000)::geometry(Polygon) AS geometry
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
			ST_Intersection(vector_tiles.geometry, hexagons.geometry) AS geometry,
			zoom_level

			FROM vector_tiles
				INNER JOIN grid.hexagons ON ST_Intersects(vector_tiles.geometry, hexagons.geometry)

			WHERE zoom_level = ANY(string_to_array(system.constant('RESULT_ZOOM_LEVELS'), ',')::int[])
	),
	unioned_intersected_areas AS (
		SELECT
			intersected_areas.receptor_id,
			ST_Union(intersected_areas.geometry) AS geometry,
			intersected_areas.zoom_level


			FROM intersected_areas
			GROUP BY intersected_areas.receptor_id, intersected_areas.zoom_level
	)
	SELECT
		unioned_intersected_areas.receptor_id,
		ST_Area(unioned_intersected_areas.geometry) AS surface,
		unioned_intersected_areas.geometry,
		unioned_intersected_areas.zoom_level

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
 * Weight is based on the surface of the intersection between habitat area and the hexagon at the given zoom level.
 *
 * The multiplication of this intersection-surface and the average coverage results in the cartographic surface (gekarteerde oppervlakte) of the
 * critical deposition area on this receptor.
 * This will be the same as determining the individual cartographic surfaces per intersected habitat area and summing those values.
 *
 * @returns Average coveragefraction for a habitat on a receptor, weighted by surface of the intersections between habitat areas and hexagon.
 */
CREATE OR REPLACE FUNCTION grid.ae_determine_habitat_coverage_on_hexagon(v_assessment_area_id integer, v_type nature.critical_deposition_area_type, v_habitat_type_id integer, v_receptor_id integer, v_zoom_level integer)
	RETURNS fraction AS
$BODY$
	WITH hexagon AS (SELECT geometry FROM grid.hexagons WHERE receptor_id = v_receptor_id AND zoom_level = v_zoom_level)
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
