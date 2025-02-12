--
-- habitats and species
--
SELECT system.raise_notice('Build: relevant_habitat_areas @ ' || timeofday());
BEGIN;
	INSERT INTO nature.relevant_habitat_areas(assessment_area_id, habitat_area_id, habitat_type_id, coverage, geometry)
		SELECT assessment_area_id, habitat_area_id, habitat_type_id, coverage, geometry
		FROM nature.build_relevant_habitat_areas_view;
COMMIT;
