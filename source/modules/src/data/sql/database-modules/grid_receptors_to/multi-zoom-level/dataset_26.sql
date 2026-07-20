BEGIN; SELECT system.load_table('receptors_to_assessment_areas', '{data_folder}/common/grid_receptors_to/multi-zoom-level/26/grid.receptors_to_assessment_areas_20260717.txt'); COMMIT;
BEGIN; SELECT system.load_table('receptors_to_critical_deposition_areas', '{data_folder}/common/grid_receptors_to/multi-zoom-level/26/grid.receptors_to_critical_deposition_areas_20260720.txt');

{import_common 'database-modules/grid_receptors_to/refresh_materialized_views.sql'}
