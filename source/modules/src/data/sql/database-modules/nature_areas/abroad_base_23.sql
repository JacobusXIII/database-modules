BEGIN; SELECT system.load_table('nature.natura2000_areas', '{data_folder}/public/natura2000_areas_abroad_20230717.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_area_properties', '{data_folder}/public/natura2000_area_properties_abroad_20230717.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_directive_areas', '{data_folder}/public/natura2000_directive_areas_abroad_20230717.txt'); COMMIT;
