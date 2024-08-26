-- When updating terrain properties, be sure to update the file used by the worker as well. This file only has effect on OpenData.
BEGIN; SELECT system.load_table('grid.terrain_properties', '{data_folder}/public/terrain_properties_20220128.txt', FALSE); COMMIT;
