BEGIN; SELECT system.load_table('nature.countries', '{data_folder}/common/nature_areas/22/nature.countries_20150721.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.authorities', '{data_folder}/common/nature_areas/22/nature.authorities_20221115.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_areas', '{data_folder}/common/nature_areas/22/nature.natura2000_areas_20220607.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_area_properties', '{data_folder}/common/nature_areas/22/nature.natura2000_area_properties_20221216.txt'); COMMIT;

BEGIN; SELECT system.load_table('nature.natura2000_directives', '{data_folder}/common/nature_areas/22/nature.natura2000_directives_20220328.txt'); COMMIT;
BEGIN; SELECT system.load_table('nature.natura2000_directive_areas', '{data_folder}/common/nature_areas/22/nature.natura2000_directive_areas_20220607.txt', FALSE); COMMIT;
