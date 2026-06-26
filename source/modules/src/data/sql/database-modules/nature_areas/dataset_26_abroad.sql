BEGIN; SELECT system.load_table('natura2000_areas', '{data_folder}/common/nature_areas/26/nature.natura2000_areas_abroad_20260414.txt'); COMMIT;
BEGIN; SELECT system.load_table('natura2000_area_properties', '{data_folder}/common/nature_areas/26/nature.natura2000_area_properties_abroad_20260414.txt'); COMMIT;

BEGIN; SELECT system.load_table('natura2000_directive_areas', '{data_folder}/common/nature_areas/26/nature.natura2000_directive_areas_abroad_20260414.txt'); COMMIT;
