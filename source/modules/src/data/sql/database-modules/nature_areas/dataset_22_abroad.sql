BEGIN; SELECT system.load_table('natura2000_areas', '{data_folder}/common/nature_areas/22/nature.natura2000_areas_abroad_20200616.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('natura2000_area_properties', '{data_folder}/common/nature_areas/22/nature.natura2000_area_properties_abroad_20200618.txt', FALSE); COMMIT;

BEGIN; SELECT system.load_table('natura2000_directive_areas', '{data_folder}/common/nature_areas/22/nature.natura2000_directive_areas_abroad_20220328.txt'); COMMIT;
