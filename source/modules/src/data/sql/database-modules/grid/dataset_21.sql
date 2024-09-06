BEGIN; SELECT system.load_table('grid.receptors', '{data_folder}/common/grid/21/grid.receptors_20210924.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('grid.hexagons', '{data_folder}/common/grid/21/grid.hexagons_20210924.txt', FALSE); COMMIT;
