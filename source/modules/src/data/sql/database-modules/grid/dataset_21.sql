BEGIN; SELECT system.load_table('receptors', '{data_folder}/common/grid/21/grid.receptors_20210924.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('hexagons', '{data_folder}/common/grid/21/grid.hexagons_20210924.txt', FALSE); COMMIT;
