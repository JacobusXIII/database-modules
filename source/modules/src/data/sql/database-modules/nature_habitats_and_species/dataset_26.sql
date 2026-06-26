{import_common 'database-modules/nature_habitats_and_species/supplied_26.sql'}

-- Generated data
BEGIN; SELECT system.load_table('relevant_habitat_areas', '{data_folder}/common/nature_habitats_and_species/26/nature.relevant_habitat_areas_20260519.txt'); COMMIT;

{import_common 'database-modules/nature_habitats_and_species/refresh_materialized_views.sql'}
