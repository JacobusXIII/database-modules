BEGIN; SELECT system.load_table('grid.receptors_to_assessment_areas', '{data_folder}/public/receptors_to_assessment_areas_20240625.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('grid.receptors_to_critical_deposition_areas', '{data_folder}/public/receptors_to_critical_deposition_areas_20240625.txt', FALSE); COMMIT;

{import_common '/database-modules/grid_to_nature/refresh.sql'}
