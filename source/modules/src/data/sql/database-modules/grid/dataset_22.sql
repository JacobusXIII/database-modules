BEGIN; SELECT system.load_table('receptors', '{data_folder}/common/grid/22/grid.receptors_20220621.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('hexagons', '{data_folder}/common/grid/22/grid.hexagons_20220621.txt', FALSE); COMMIT;
