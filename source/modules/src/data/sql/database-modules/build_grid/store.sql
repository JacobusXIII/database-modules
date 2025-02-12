-- TODO: refactor to a store_table
SELECT system.store_query(
	'grid.geometry_of_interests',
	$$ SELECT * FROM grid.geometry_of_interests ORDER BY assessment_area_id $$,
	'{data_folder}/export/{tablename}_{datesuffix}.txt'
);


SELECT system.store_query(
	'grid.grid.receptors',
	$$ SELECT  * FROM grid.receptors ORDER BY receptor_id $$,
	'{data_folder}/export/{tablename}_{datesuffix}.txt'
);


SELECT system.store_query(
	'grid.hexagons',
	$$ SELECT * FROM grid.hexagons ORDER BY receptor_id, zoom_level $$,
	'{data_folder}/export/{tablename}_{datesuffix}.txt'
);
