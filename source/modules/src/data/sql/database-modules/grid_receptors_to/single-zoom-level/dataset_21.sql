BEGIN; SELECT system.load_table('receptors_to_assessment_areas', '{data_folder}/common/grid_receptors_to/single-zoom-level/21/grid.receptors_to_assessment_areas_20210924.txt', FALSE); COMMIT;
BEGIN; SELECT system.load_table('receptors_to_critical_deposition_areas', '{data_folder}/common/grid_receptors_to/single-zoom-level/21/grid.receptors_to_critical_deposition_areas_20211015.txt', FALSE); COMMIT;

{import_common 'database-modules/grid_receptors_to/refresh_materialized_views.sql'}
