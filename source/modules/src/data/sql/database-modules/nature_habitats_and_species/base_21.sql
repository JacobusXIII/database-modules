{import_common '/database-modules/nature_habitats_and_species/supplied_21.sql'}

-- Generated data
BEGIN; SELECT system.load_table('nature.relevant_habitat_areas', '{data_folder}/public/relevant_habitat_areas_20210924.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.habitats', '{data_folder}/public/habitats_20210924.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.relevant_habitats', '{data_folder}/public/relevant_habitats_20210924.txt', FALSE); COMMIT;
