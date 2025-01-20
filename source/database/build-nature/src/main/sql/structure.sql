CREATE EXTENSION postgis;

{import_common 'database-build/public/'}
{import_common 'database-build/essentials.sql'}
{import_common 'database-build/toolbox.sql'}

{import_common 'database-modules/aerius-general/'}

CREATE SCHEMA nature;

{import_common_into_schema 'database-modules/nature_areas/', 'nature'}
{import_common_into_schema 'database-modules/nature_habitats_and_species/', 'nature'}
{import_common_into_schema 'database-modules/build_nature/', 'nature'}
