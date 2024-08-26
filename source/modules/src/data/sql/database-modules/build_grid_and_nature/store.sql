--
-- habitats and species
--
BEGIN; SELECT system.store_table('nature.relevant_habitat_areas', '/tmp/{tablename}_{datesuffix}.txt'); COMMIT;
BEGIN; SELECT system.store_table('nature.habitats', '/tmp/{tablename}_{datesuffix}.txt'); COMMIT;
BEGIN; SELECT system.store_table('nature.relevant_habitats', '/tmp/{tablename}_{datesuffix}.txt'); COMMIT;

--
-- grid
--
BEGIN;

CREATE TABLE grid.temp_nl_receptors AS
SELECT
	DISTINCT receptor_id
	FROM grid.geometry_of_interests
		INNER JOIN nature.assessment_areas USING (assessment_area_id)
		INNER JOIN nature.authorities USING (authority_id)
		INNER JOIN grid.receptors ON ST_Within(receptors.geometry, geometry_of_interests.geometry)
	WHERE authorities.country_id = 1
;

CREATE UNIQUE INDEX idx_temp_nl_receptors ON grid.temp_nl_receptors (receptor_id);


SELECT system.store_query(
	'receptors',
	$$ SELECT receptors.* 
			FROM grid.receptors
				INNER JOIN grid.temp_nl_receptors USING (receptor_id)
			ORDER BY receptor_id 
	$$,
	'/tmp/{tablename}_{datesuffix}.txt'
);


SELECT system.store_query(
	'hexagons',
	$$ SELECT hexagons.* 
			FROM grid.hexagons
				INNER JOIN grid.temp_nl_receptors USING (receptor_id)
			ORDER BY receptor_id, zoom_level
	$$,
	'/tmp/{tablename}_{datesuffix}.txt'
);

DROP TABLE grid.temp_nl_receptors CASCADE;

COMMIT;

BEGIN; SELECT system.store_table('grid.geometry_of_interests', '/tmp/{tablename}_{datesuffix}.txt'); COMMIT;

--
-- grid to nature
--
BEGIN; SELECT system.store_table('grid.receptors_to_assessment_areas', '/tmp/{tablename}_{datesuffix}.txt'); COMMIT;
BEGIN; SELECT system.store_table('grid.receptors_to_critical_deposition_areas', '/tmp/{tablename}_{datesuffix}.txt'); COMMIT;
