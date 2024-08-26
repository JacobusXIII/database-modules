/*
 * receptors_to_habitats_view
 * --------------------------
 * View on receptors_to_critical_deposition_areas returning only the type 'habitat', using habitat_type_id.
 */
CREATE OR REPLACE VIEW grid.receptors_to_habitats_view AS
SELECT
	assessment_area_id,
	critical_deposition_area_id AS habitat_type_id,
	receptor_id,
	surface,
	receptor_habitat_coverage

	FROM grid.receptors_to_critical_deposition_areas

	WHERE type = 'habitat'
;


/*
 * receptors_to_relevant_habitats_view
 * -----------------------------------
 * View on receptors_to_critical_deposition_areas returning only the type 'relevant_habitat', using habitat_type_id.
 */
CREATE OR REPLACE VIEW grid.receptors_to_relevant_habitats_view AS
SELECT
	assessment_area_id,
	critical_deposition_area_id AS habitat_type_id,
	receptor_id,
	surface,
	receptor_habitat_coverage

	FROM grid.receptors_to_critical_deposition_areas

	WHERE type = 'relevant_habitat'
;


/*
 * receptors_to_assessment_areas_on_critical_deposition_area_view
 * --------------------------------------------------------------
 * View reducing receptors_to_critical_deposition_areas to a link between assessment areas and receptors.
 * This only includes receptors within a critical deposition area.
 * The type of critical deposition area must be filtered by 'type'.
 * Surface and weight are based on the assessment area/receptor relation (critical deposition areas are combined).
 */
CREATE OR REPLACE VIEW grid.receptors_to_assessment_areas_on_critical_deposition_area_view AS
SELECT
	assessment_area_id,
	receptor_id,
	type,
	SUM(surface * receptor_habitat_coverage / 10000.0)::real AS weight,  --coverage meenemen
	SUM(surface) AS surface,
	SUM(surface * receptor_habitat_coverage) AS cartographic_surface

	FROM grid.receptors_to_critical_deposition_areas

	GROUP BY assessment_area_id, receptor_id, type
;


/*
 * receptors_to_assessment_areas_on_relevant_habitat_view
 * ------------------------------------------------------
 * View similar as receptors_to_assessment_areas_on_critical_deposition_area_view, but only where type = 'relevant_habitat'.
 */
CREATE OR REPLACE VIEW grid.receptors_to_assessment_areas_on_relevant_habitat_view AS
SELECT
	assessment_area_id,
	receptor_id,
	weight,
	surface,
	cartographic_surface

	FROM grid.receptors_to_assessment_areas_on_critical_deposition_area_view

	WHERE type = 'relevant_habitat'
;


/*
 * critical_depositions_view
 * -------------------------
 * View returing the critical deposition value (KDW) per receptor.
 * Each critical depostion area has a KDW.
 * To determine the KDW per receptor, all relevant critical deposition areas within the assessment area intersecting with the hexagon at zoom level 1 are determined.
 * From this selection the lowest (=most critical) KDW value is used per receptor, independent of the surface size of the intersection.
 */
CREATE OR REPLACE VIEW grid.critical_depositions_view AS
SELECT
	receptor_id,
	MIN(critical_level) AS critical_deposition

	FROM grid.critical_levels

	WHERE substance_id= 1711
		AND result_type = 'deposition'

	GROUP BY receptor_id
;


/*
 * relevant_habitat_info_for_receptor_view
 * ---------------------------------------
 * General information about habitat areas that intersect with a hexagon.
 * The cartographic_surface is the cartographic surface (gekarteerde oppervlakte) of the habitat type that intersects with a hexagon.
 * The coverage of each individual habitat area is taken into account.
 * Use 'receptor_id' in the where-clause.
 *
 * Note: No intermediate table is used because all intermediate tables that we use so far are assessment_area based.
 * For receptors containing multiple assessment areas with the same habitat type this wosuld cause duplications.
 * This view is fast enough, as long as 'receptor_id' is used in the where-clause.
 */
CREATE OR REPLACE VIEW grid.relevant_habitat_info_for_receptor_view AS
SELECT
	receptor_id,
	habitat_type_id,
	name,
	description,
	substance_id,
	result_type,
	critical_level,
	SUM(surface * receptor_habitat_coverage)::posreal AS cartographic_surface

	FROM grid.receptors_to_relevant_habitats_view
		INNER JOIN nature.habitat_types USING (habitat_type_id)
		INNER JOIN nature.habitat_type_critical_levels USING (habitat_type_id)

	GROUP BY receptor_id, habitat_type_id, name, description, substance_id, result_type, critical_level
;


/*
 * wms_relevant_habitat_info_for_receptor_view
 * -------------------------------------------
 * WMS view returning the habitat areas that intersect with a receptor/hexagon.
 * Us 'receptor_id' and 'habitat_type_id' in the where-clause.
 *
 * The geometries are returned per assessment_area_id, to avoid having to use the slow ST_Union function.
 * Graphically this results in a line on the borders.
 */
CREATE OR REPLACE VIEW grid.wms_relevant_habitat_info_for_receptor_view AS
SELECT
	receptor_id,
	assessment_area_id,
	habitat_type_id,
	geometry

	FROM grid.receptors_to_relevant_habitats_view
		INNER JOIN nature.relevant_habitats USING (assessment_area_id, habitat_type_id)
;

/*
 * wms_habitat_areas_sensitivity_level_view
 * ----------------------------------------
 * WMS view returning habitat areas including critical level, substance, emission result type and relevance.
 */
CREATE OR REPLACE VIEW grid.wms_habitat_areas_sensitivity_level_view AS
SELECT
	habitat_areas.habitat_area_id,
	habitat_areas.habitat_type_id,
	habitat_type_critical_levels.critical_level AS critical_level,
	relevant_habitat_areas.habitat_type_id IS NOT NULL AS relevant,
	habitat_type_critical_levels.substance_id,
	habitat_type_critical_levels.result_type as emission_result_type,
	habitat_areas.geometry,
	relevant_habitat_areas.geometry AS relevant_geometry

	FROM nature.habitat_areas
		JOIN nature.habitat_types USING (habitat_type_id)
		JOIN nature.habitat_type_critical_levels USING (habitat_type_id)
		LEFT JOIN nature.relevant_habitat_areas USING (habitat_area_id, assessment_area_id, habitat_type_id)
;
