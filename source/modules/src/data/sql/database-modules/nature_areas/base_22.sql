BEGIN; SELECT system.load_table('nature.countries', '{data_folder}/temp/temp_countries_20150721.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.authorities', '{data_folder}/public/authorities_20221115.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_areas', '{data_folder}/public/natura2000_areas_20220607.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_area_properties', '{data_folder}/public/natura2000_area_properties_20221216.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_directives', '{data_folder}/public/natura2000_directives_20220328.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_directive_areas', '{data_folder}/public/natura2000_directive_areas_20220607.txt', FALSE); COMMIT;
