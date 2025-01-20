--
-- habitats and species
--
BEGIN; SELECT system.store_table('relevant_habitat_areas', '{data_folder}/export/{tablename}_{datesuffix}.txt'); COMMIT;
BEGIN; SELECT system.store_table('habitats', '{data_folder}/export/{tablename}_{datesuffix}.txt'); COMMIT;
BEGIN; SELECT system.store_table('relevant_habitats', '{data_folder}/export/{tablename}_{datesuffix}.txt'); COMMIT;
