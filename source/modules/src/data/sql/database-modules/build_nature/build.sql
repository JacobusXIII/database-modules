--
-- habitats and species
--
SELECT system.raise_notice('Build: nature.habitats @ ' || timeofday());
BEGIN;
	INSERT INTO nature.habitats(assessment_area_id, habitat_type_id, habitat_coverage, geometry)
		SELECT assessment_area_id, habitat_type_id, habitat_coverage, geometry
		FROM nature.build_habitats_view;
COMMIT;

SELECT system.raise_notice('Build: nature.relevant_habitat_areas @ ' || timeofday());
BEGIN;
	INSERT INTO nature.relevant_habitat_areas(assessment_area_id, habitat_area_id, habitat_type_id, coverage, geometry)
		SELECT assessment_area_id, habitat_area_id, habitat_type_id, coverage, geometry
		FROM nature.build_relevant_habitat_areas_view;
COMMIT;

SELECT system.raise_notice('Build: nature.relevant_habitats @ ' || timeofday());
BEGIN;
	INSERT INTO nature.relevant_habitats(assessment_area_id, habitat_type_id, habitat_coverage, geometry)
		SELECT assessment_area_id, habitat_type_id, habitat_coverage, geometry
		FROM nature.build_relevant_habitats_view;
COMMIT;
