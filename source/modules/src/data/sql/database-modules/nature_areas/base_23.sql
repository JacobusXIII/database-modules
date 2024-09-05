BEGIN; SELECT system.load_table('nature.countries', '{data_folder}/common/nature_areas/23/nature.countries_20150721.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.authorities', '{data_folder}/common/nature_areas/23/nature.authorities_20221115.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_areas', '{data_folder}/common/nature_areas/23/nature.natura2000_areas_20230503.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_area_properties', '{data_folder}/common/nature_areas/23/nature.natura2000_area_properties_20230404.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_directives', '{data_folder}/common/nature_areas/23/nature.natura2000_directives_20220328.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_directive_areas', '{data_folder}/common/nature_areas/23/nature.natura2000_directive_areas_20230503.txt'); COMMIT;
