--
-- habitats and species
--
SELECT system.raise_notice('Build: habitats @ ' || timeofday());
BEGIN;
	INSERT INTO habitats(assessment_area_id, habitat_type_id, habitat_coverage, geometry)
		SELECT assessment_area_id, habitat_type_id, habitat_coverage, geometry
		FROM build_habitats_view;
COMMIT;

SELECT system.raise_notice('Build: relevant_habitat_areas @ ' || timeofday());
BEGIN;
	INSERT INTO relevant_habitat_areas(assessment_area_id, habitat_area_id, habitat_type_id, coverage, geometry)
		SELECT assessment_area_id, habitat_area_id, habitat_type_id, coverage, geometry
		FROM build_relevant_habitat_areas_view;
COMMIT;

SELECT system.raise_notice('Build: relevant_habitats @ ' || timeofday());
BEGIN;
	INSERT INTO relevant_habitats(assessment_area_id, habitat_type_id, habitat_coverage, geometry)
		SELECT assessment_area_id, habitat_type_id, habitat_coverage, geometry
		FROM build_relevant_habitats_view;
COMMIT;
