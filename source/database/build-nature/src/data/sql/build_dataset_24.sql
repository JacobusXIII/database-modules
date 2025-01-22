BEGIN; SELECT system.load_table('nature.countries', '{data_folder}/aeriusII/UK/public/countries_20211110.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.authorities', '{data_folder}/aeriusII/UK/public/authorities_20220128.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_areas', '{data_folder}/aeriusII/UK/public/natura2000_areas_20240517.txt', TRUE); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_directives', '{data_folder}/aeriusII/UK/public/natura2000_directives_20220408.txt', TRUE); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_directive_areas', '{data_folder}/aeriusII/UK/public/natura2000_directive_areas_20240517.txt', TRUE); COMMIT;

-- UK has no specific natura2000_area_properties, so insert something sensible for now.
-- definitief is a dutch term, but that's needed due to enum aspect. It ensures that every habitat_area within the natura2000_area is considered relevant.
BEGIN;
INSERT INTO nature.natura2000_area_properties (natura2000_area_id, registered_surface, design_status)
	SELECT natura2000_area_id, ST_Area(geometry), 'definitief' FROM nature.natura2000_areas;
COMMIT;

BEGIN; SELECT system.load_table('nature.habitat_types', '{data_folder}/aeriusII/UK/public/habitat_types_20240517.txt', TRUE); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_type_critical_levels', '{data_folder}/aeriusII/UK/public/habitat_type_critical_levels_20240517.txt', TRUE); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_areas', '{data_folder}/aeriusII/UK/public/habitat_areas_20240517.txt', TRUE); COMMIT;

-- UK has no specific habitat relations or properties data either, so insert something sensible for now.
-- Since we have no other information, use a 1:1 relation between habitat type and goal habitat type
BEGIN;
INSERT INTO nature.habitat_type_relations (habitat_type_id, goal_habitat_type_id)
	SELECT habitat_type_id, habitat_type_id FROM nature.habitat_types;
COMMIT;

-- All habitat-areas are going to be marked as relevant
-- (level isn't entirely correct, but can't use 'none' and nothing else really seems to match)
BEGIN;
INSERT INTO nature.habitat_properties (goal_habitat_type_id, assessment_area_id, quality_goal, extent_goal, design_status)
	SELECT DISTINCT habitat_type_id, assessment_area_id, 'level'::nature.habitat_goal_type, 'level'::nature.habitat_goal_type, 'definitief'::nature.design_status_type
		FROM nature.habitat_areas;
COMMIT;

{import_common_into_schema 'database-modules/build_nature/build.sql', 'nature'}
{import_common_into_schema 'database-modules/build_nature/store.sql', 'nature'}
