BEGIN; SELECT system.load_table('grid.receptors', '{data_folder}/public/receptors_20220621.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('grid.hexagons', '{data_folder}/public/hexagons_20220621.txt', FALSE); COMMIT;
