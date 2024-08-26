BEGIN; SELECT system.load_table('nature.habitat_types', '{data_folder}/public/habitat_types_20230619.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_type_critical_levels', '{data_folder}/public/habitat_type_critical_levels_20230619.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_properties', '{data_folder}/public/habitat_properties_20221216.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.habitat_type_relations', '{data_folder}/public/habitat_type_relations_20230619.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.habitat_areas', '{data_folder}/public/habitat_areas_20230704.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.species', '{data_folder}/public/species_20221216.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.species_properties', '{data_folder}/public/species_properties_20221216.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.designated_species', '{data_folder}/public/designated_species_20221216.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.species_to_habitats', '{data_folder}/public/species_to_habitats_20230516.txt'); COMMIT;
