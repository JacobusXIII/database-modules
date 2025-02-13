SELECT system.raise_notice('Build: receptors_to_assessment_areas @ ' || timeofday());

BEGIN;
{multithread on: SELECT assessment_area_id FROM nature.assessment_areas ORDER BY assessment_area_id}
	INSERT INTO grid.receptors_to_assessment_areas (receptor_id, assessment_area_id, zoom_level, surface)
	SELECT
		receptor_id,
		assessment_area_id,
		zoom_level,
		surface

		FROM grid.build_receptors_to_assessment_areas_view
		
		WHERE assessment_area_id = {assessment_area_id};
{/multithread}
COMMIT;


SELECT system.raise_notice('Build: receptors_to_critical_deposition_areas @ ' || timeofday());

BEGIN;
{multithread on: SELECT assessment_area_id FROM nature.assessment_areas ORDER BY assessment_area_id}
	INSERT INTO grid.receptors_to_critical_deposition_areas (assessment_area_id, type, critical_deposition_area_id, receptor_id, zoom_level, surface, receptor_habitat_coverage)
	SELECT
		assessment_area_id,
		type,
		critical_deposition_area_id,
		receptor_id,
		zoom_level,
		surface,
		receptor_habitat_coverage

		FROM grid.build_receptors_to_critical_deposition_areas_view
		
		WHERE assessment_area_id = {assessment_area_id};
{/multithread}
COMMIT;
