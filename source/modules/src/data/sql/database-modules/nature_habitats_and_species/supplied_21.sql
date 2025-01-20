BEGIN; SELECT system.load_table('habitat_types', '{data_folder}/common/nature_habitats_and_species/21/nature.habitat_types_20200730.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('habitat_type_critical_levels', '{data_folder}/common/nature_habitats_and_species/21/nature.habitat_type_critical_levels_20200730.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('habitat_properties', '{data_folder}/common/nature_habitats_and_species/21/nature.habitat_properties_20200727.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('habitat_type_relations', '{data_folder}/common/nature_habitats_and_species/21/nature.habitat_type_relations_20200730.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('habitat_areas', '{data_folder}/common/nature_habitats_and_species/21/nature.habitat_areas_20210903.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('species', '{data_folder}/common/nature_habitats_and_species/21/nature.species_20200526.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('species_properties', '{data_folder}/common/nature_habitats_and_species/21/nature.species_properties_20200727.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('designated_species', '{data_folder}/common/nature_habitats_and_species/21/nature.designated_species_20200727.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('species_to_habitats', '{data_folder}/common/nature_habitats_and_species/21/nature.species_to_habitats_20200714.txt', FALSE); COMMIT;
