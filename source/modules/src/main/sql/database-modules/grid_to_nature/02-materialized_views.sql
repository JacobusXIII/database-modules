/*
 * included_receptors
 * ------------------
 * Materialized view returning the 'included' receptors.
 *
 * A receptor is only included in overviews when present in this table.
 * The receptor can for example be excluded when they are to close to a source, which would make the results for this receptor point incorrect.
 * Another reason would be that the receptor (through zoom level 1 hexagon) did not cover a relevant habitat area.
 */
CREATE MATERIALIZED VIEW grid.included_receptors AS
SELECT DISTINCT
	receptor_id

	FROM grid.receptors_to_critical_deposition_areas

	WHERE type = 'relevant_habitat'
;


/*
 * critical_levels
 * ---------------
 * Materialized view returning the critical levels per receptor per substance/result type.
 *
 * Each habitat type can have critical levels for a substance/result type combination.
 * To determine the values in this table, the critical level for relevant habitat areas that intersect with the zoom level 1 hexagon are used.
 * Per receptor, the lowest (=most strict) critical level value is used, no matter the surface size that is covered.
 */
CREATE MATERIALIZED VIEW grid.critical_levels AS
SELECT
	receptor_id,
	substance_id,
	result_type,
	MIN(critical_level) AS critical_level

	FROM grid.receptors_to_critical_deposition_areas
		INNER JOIN nature.critical_deposition_areas_view USING (assessment_area_id, type, critical_deposition_area_id)
		INNER JOIN nature.habitat_type_critical_levels ON (critical_deposition_area_id = habitat_type_id)

	WHERE type = 'relevant_habitat'
		AND habitat_type_critical_levels.sensitive = TRUE
		AND critical_level IS NOT NULL

	GROUP BY receptor_id, substance_id, result_type
;


/*
 * hexagon_type_receptors
 * ----------------------
 * Materialized view returning per hexagon type which receptors belong to that type.
 */
CREATE MATERIALIZED VIEW grid.hexagon_type_receptors AS
SELECT
	'relevant_hexagons'::grid.hexagon_type AS hexagon_type,
	receptor_id

	FROM grid.included_receptors
UNION ALL
SELECT
	'exceeding_hexagons'::grid.hexagon_type AS hexagon_type,
	receptor_id

	FROM grid.included_receptors
		LEFT JOIN grid.non_exceeding_receptors USING (receptor_id)

	WHERE non_exceeding_receptors.receptor_id IS NULL
;

CREATE INDEX idx_hexagon_type_receptors_receptor_id ON grid.hexagon_type_receptors (receptor_id);


/*
 * receptors_to_relevant_habitats
 * ------------------------------
 * Materialized view returning the link between relevant habitats and hexagons (by receptor_id).
 *
 * @column cartographic_surface Surface for which the coverage is taken into account alongside the intersection of hexagon and critical deposition area.
 */
CREATE MATERIALIZED VIEW grid.receptors_to_relevant_habitats AS
SELECT 
	assessment_area_id, 
	critical_deposition_area_id, 
	receptor_id,
	surface * receptor_habitat_coverage AS cartographic_surface
	
	FROM grid.receptors_to_critical_deposition_areas
	WHERE type = 'relevant_habitat'
;

CREATE INDEX idx_receptors_to_relevant_habitats ON grid.receptors_to_relevant_habitats (receptor_id);
