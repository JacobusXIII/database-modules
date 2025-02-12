SELECT system.raise_notice('Build: receptors_to_assessment_areas @ ' || timeofday());

BEGIN;
{multithread on: SELECT assessment_area_id FROM nature.assessment_areas ORDER BY assessment_area_id}
	INSERT INTO grid.receptors_to_assessment_areas (receptor_id, assessment_area_id, surface)
	SELECT
		receptor_id,
		assessment_area_id,
		surface

		FROM grid.build_receptors_to_assessment_areas_view
		
		WHERE assessment_area_id = {assessment_area_id};
{/multithread}
COMMIT;


SELECT system.raise_notice('Build: receptors_to_critical_deposition_areas @ ' || timeofday());

BEGIN;
{multithread on: SELECT assessment_area_id FROM nature.assessment_areas ORDER BY assessment_area_id}
	INSERT INTO grid.receptors_to_critical_deposition_areas (assessment_area_id, type, critical_deposition_area_id, receptor_id, surface, receptor_habitat_coverage)
	SELECT
		assessment_area_id,
		type,
		critical_deposition_area_id,
		receptor_id,
		surface,
		receptor_habitat_coverage

		FROM grid.build_receptors_to_critical_deposition_areas_view
		
		WHERE assessment_area_id = {assessment_area_id};
{/multithread}
COMMIT;


-- TODO: refactor to materialized view
SELECT system.raise_notice('Build: receptors_to_relevant_habitats @ ' || timeofday());

BEGIN;
	INSERT INTO grid.receptors_to_relevant_habitats (assessment_area_id, critical_deposition_area_id, receptor_id, cartographic_surface)
	SELECT 
		assessment_area_id, 
		critical_deposition_area_id, 
		receptor_id,
		surface * receptor_habitat_coverage AS cartographic_surface
		
		FROM grid.receptors_to_critical_deposition_areas
		
		WHERE type = 'relevant_habitat';
COMMIT;
