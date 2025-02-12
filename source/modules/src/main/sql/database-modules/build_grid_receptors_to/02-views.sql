/*
 * build_receptors_to_assessment_areas_view
 * ----------------------------------------
 * View to fill the receptors_to_assessment_areas table.
 */
CREATE OR REPLACE VIEW grid.build_receptors_to_assessment_areas_view AS
SELECT
	assessment_area_id,
	(grid.ae_determine_hexagon_intersections(geometry)).receptor_id,
	(grid.ae_determine_hexagon_intersections(geometry)).zoom_level,
	(grid.ae_determine_hexagon_intersections(geometry)).surface

	FROM nature.assessment_areas

	WHERE assessment_areas.type = 'natura2000_area'
;


/*
 * build_receptors_to_critical_deposition_areas_view
 * -------------------------------------------------
 * View to fill the receptors_to_critical_deposition_areas table.
 *
 * The coverage of the habitat on each receptor is calculated by looking at the intersection of the habitat areas that intersect the receptor.
 * See {@link ae_determine_habitat_coverage_on_hexagon} for the calculation method.
 */
CREATE OR REPLACE VIEW grid.build_receptors_to_critical_deposition_areas_view AS
SELECT
	assessment_area_id,
	type,
	critical_deposition_area_id,
	receptor_id,
	zoom_level,
	surface,
	grid.ae_determine_habitat_coverage_on_hexagon(assessment_area_id, type, critical_deposition_area_id, receptor_id, zoom_level::integer) AS receptor_habitat_coverage

	FROM
	(SELECT
		assessment_area_id,
		type,
		critical_deposition_area_id,
		(grid.ae_determine_hexagon_intersections(geometry)).receptor_id,
		(grid.ae_determine_hexagon_intersections(geometry)).surface,
		(grid.ae_determine_hexagon_intersections(geometry)).zoom_level

		FROM nature.critical_deposition_areas_view
	) AS mapping_receptor_cda
;