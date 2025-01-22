BEGIN; SELECT system.load_table('receptors', '{data_folder}/common/grid/24/grid.receptors_20240625.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('hexagons', '{data_folder}/common/grid/24/grid.hexagons_20240625.txt', FALSE); COMMIT;
