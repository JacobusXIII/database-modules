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


--
-- grid
--
SELECT system.raise_notice('Build: grid.geometry_of_interests @ ' || timeofday());
BEGIN; SELECT grid.ae_build_geometry_of_interests(); COMMIT;

SELECT system.raise_notice('Build: grid.receptors @ ' || timeofday());
BEGIN; SELECT grid.ae_build_receptors(); COMMIT;

SELECT system.raise_notice('Build: grid.hexagons @ ' || timeofday());
BEGIN; SELECT grid.ae_build_hexagons(); COMMIT;


--
-- grid to nature
--
SELECT system.raise_notice('Build: grid.receptors_to_critical_deposition_areas @ ' || timeofday());
BEGIN;
	INSERT INTO grid.receptors_to_critical_deposition_areas(assessment_area_id, type, critical_deposition_area_id, receptor_id, surface, receptor_habitat_coverage)
		SELECT assessment_area_id, type, critical_deposition_area_id, receptor_id, surface, receptor_habitat_coverage
		FROM grid.build_receptors_to_critical_deposition_areas_view;
COMMIT;

SELECT system.raise_notice('Build: grid.receptors_to_critical_deposition_areas @ ' || timeofday());
BEGIN;
	INSERT INTO grid.receptors_to_critical_deposition_areas(assessment_area_id, type, critical_deposition_area_id, receptor_id, surface, receptor_habitat_coverage)
		SELECT assessment_area_id, type, critical_deposition_area_id, receptor_id, surface, receptor_habitat_coverage
		FROM grid.build_receptors_to_critical_deposition_areas_view;
COMMIT;
