BEGIN; SELECT system.load_table('receptors', '{data_folder}/common/grid/25/grid.receptors_20250519.txt'); COMMIT;
BEGIN; SELECT system.load_table('hexagons', '{data_folder}/common/grid/25/grid.hexagons_20250519.txt'); COMMIT;
