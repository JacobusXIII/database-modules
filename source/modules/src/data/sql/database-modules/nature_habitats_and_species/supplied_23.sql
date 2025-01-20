BEGIN; SELECT system.load_table('habitat_types', '{data_folder}/common/nature_habitats_and_species/23/nature.habitat_types_20230619.txt'); COMMIT;
BEGIN; SELECT system.load_table('habitat_type_critical_levels', '{data_folder}/common/nature_habitats_and_species/23/nature.habitat_type_critical_levels_20230619.txt'); COMMIT;
BEGIN; SELECT system.load_table('habitat_properties', '{data_folder}/common/nature_habitats_and_species/23/nature.habitat_properties_20221216.txt'); COMMIT;
BEGIN; SELECT system.load_table('habitat_type_relations', '{data_folder}/common/nature_habitats_and_species/23/nature.habitat_type_relations_20230619.txt'); COMMIT;

BEGIN; SELECT system.load_table('habitat_areas', '{data_folder}/common/nature_habitats_and_species/23/nature.habitat_areas_20230704.txt'); COMMIT;

BEGIN; SELECT system.load_table('species', '{data_folder}/common/nature_habitats_and_species/23/nature.species_20221216.txt'); COMMIT;
BEGIN; SELECT system.load_table('species_properties', '{data_folder}/common/nature_habitats_and_species/23/nature.species_properties_20221216.txt'); COMMIT;
BEGIN; SELECT system.load_table('designated_species', '{data_folder}/common/nature_habitats_and_species/23/nature.designated_species_20221216.txt'); COMMIT;

BEGIN; SELECT system.load_table('species_to_habitats', '{data_folder}/common/nature_habitats_and_species/23/nature.species_to_habitats_20230516.txt'); COMMIT;
