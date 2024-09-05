BEGIN; SELECT system.load_table('grid.receptors', '{data_folder}/common/grid/23/grid.receptors_20230511.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('grid.hexagons', '{data_folder}/common/grid/23/grid.hexagons_20230511.txt', FALSE); COMMIT;
