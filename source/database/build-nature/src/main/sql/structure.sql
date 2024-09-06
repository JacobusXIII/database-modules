CREATE EXTENSION postgis;

{import_common 'database-build/public/'}
{import_common 'database-build/essentials.sql'}
{import_common 'database-build/toolbox.sql'}

{import_common 'database-modules/aerius-general/'}

{import_common 'database-modules/nature_areas/'}
{import_common 'database-modules/nature_habitats_and_species/'}
{import_common 'database-modules/build_nature/'}
