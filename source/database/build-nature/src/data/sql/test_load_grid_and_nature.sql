CREATE OR REPLACE FUNCTION truncate_tables_in_schemas(schema_names text[], exclude_tables text[] DEFAULT NULL)
	RETURNS void AS
$BODY$
DECLARE
    r RECORD;
    full_table_name text;
BEGIN
    FOR full_table_name IN (
        SELECT schemaname || '.' || tablename
        	FROM pg_tables
        	WHERE schemaname = ANY(schema_names)
        	ORDER BY schemaname, tablename
    )
    LOOP
        IF exclude_tables IS NOT NULL AND full_table_name = ANY (exclude_tables) THEN
            RAISE NOTICE 'Skipping table: %', full_table_name;
        ELSE
            EXECUTE 'TRUNCATE TABLE ' || full_table_name || ' CASCADE;';
            RAISE NOTICE 'Truncated table: %', full_table_name;
        END IF;
    END LOOP;
END;
$BODY$
LANGUAGE plpgsql;


--
-- Load all the grid- and nature data for all the base years.
--
{import_common 'database-modules/grid/base_21.sql'}
{import_common 'database-modules/nature_areas/base_21.sql'}
{import_common 'database-modules/nature_habitats_and_species/base_21.sql'}


BEGIN; SELECT truncate_tables_in_schemas(ARRAY['grid', 'nature']); COMMIT;

{import_common 'database-modules/grid/base_22.sql'}
{import_common 'database-modules/nature_areas/base_22.sql'}
{import_common 'database-modules/nature_areas/abroad_base_22.sql'}
{import_common 'database-modules/nature_habitats_and_species/base_22.sql'}


BEGIN; SELECT truncate_tables_in_schemas(ARRAY['grid', 'nature']); COMMIT;

{import_common 'database-modules/grid/base_23.sql'}
{import_common 'database-modules/nature_areas/base_23.sql'}
{import_common 'database-modules/nature_areas/abroad_base_23.sql'}
{import_common 'database-modules/nature_habitats_and_species/base_23.sql'}


BEGIN; SELECT truncate_tables_in_schemas(
		ARRAY['grid', 'nature'],
		ARRAY['nature.countries', 'nature.authorities', 'nature.assessment_areas', 'nature.natura2000_areas', 
			'nature.natura2000_area_properties', 'nature.natura2000_directives', 'nature.natura2000_directive_areas']
	); COMMIT;

{import_common 'database-modules/grid/base_24.sql'}
{import_common 'database-modules/nature_habitats_and_species/base_24.sql'}
