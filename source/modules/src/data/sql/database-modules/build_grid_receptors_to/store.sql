SELECT system.store_table('grid.receptors_to_assessment_areas', '{data_folder}/export/{tablename}_{datesuffix}.txt');
SELECT system.store_table('grid.receptors_to_critical_deposition_areas', '{data_folder}/export/{tablename}_{datesuffix}.txt');

-- TODO: looks like receptors_to_relevant_habitats isn't stored
