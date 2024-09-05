BEGIN; SELECT system.load_table('grid.receptors', '{data_folder}/common/grid/24/grid.receptors_20240625.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('grid.hexagons', '{data_folder}/common/grid/24/grid.hexagons_20240625.txt', FALSE); COMMIT;
