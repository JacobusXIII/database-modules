BEGIN; SELECT system.load_table('receptors', '{data_folder}/common/grid/23/grid.receptors_20230511.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('hexagons', '{data_folder}/common/grid/23/grid.hexagons_20230511.txt', FALSE); COMMIT;
