BEGIN; SELECT system.load_table('receptors_to_assessment_areas', '{data_folder}/common/grid_receptors_to/multi-zoom-level/25/grid.receptors_to_assessment_areas_20250519.txt'); COMMIT;
BEGIN; SELECT system.load_table('receptors_to_critical_deposition_areas', '{data_folder}/common/grid_receptors_to/multi-zoom-level/25/grid.receptors_to_critical_deposition_areas_20250519.txt');

{import_common 'database-modules/grid_receptors_to/refresh_materialized_views.sql'}
