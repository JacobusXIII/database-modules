{import_common 'database-modules/nature_habitats_and_species/supplied_24.sql'}

-- Generated data
BEGIN; SELECT system.load_table('relevant_habitat_areas', '{data_folder}/common/nature_habitats_and_species/24/nature.relevant_habitat_areas_20240625.txt', FALSE); COMMIT;

{import_common 'database-modules/nature_habitats_and_species/refresh_materialized_views.sql'}
