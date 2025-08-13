--
-- habitats and species
--
BEGIN; SELECT system.store_table('relevant_habitat_areas', '{data_folder}/export/nature.{tablename}_{datesuffix}.txt'); COMMIT;
