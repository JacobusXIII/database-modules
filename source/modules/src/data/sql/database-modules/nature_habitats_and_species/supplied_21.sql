BEGIN; SELECT system.load_table('nature.habitat_types', '{data_folder}/public/habitat_types_20200730.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_type_critical_levels', '{data_folder}/public/habitat_type_critical_levels_20200730.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_properties', '{data_folder}/public/habitat_properties_20200727.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_type_relations', '{data_folder}/public/habitat_type_relations_20200730.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('nature.habitat_areas', '{data_folder}/public/habitat_areas_20210903.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('nature.species', '{data_folder}/public/species_20200526.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.species_properties', '{data_folder}/public/species_properties_20200727.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.designated_species', '{data_folder}/public/designated_species_20200727.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('nature.species_to_habitats', '{data_folder}/public/species_to_habitats_20200714.txt', FALSE); COMMIT;
