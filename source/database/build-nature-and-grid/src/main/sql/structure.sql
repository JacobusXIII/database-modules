CREATE EXTENSION postgis;

{import_common 'database-build/public/'}
{import_common 'database-build/essentials.sql'}
{import_common 'database-build/toolbox.sql'}

{import_common 'database-modules/aerius_general/'}
{import_common 'database-modules/aerius_constants/nl-constants.sql'}

--
-- Nature
--
CREATE SCHEMA nature;

-- Habitats and species
{import_common_into_schema 'database-modules/nature_areas/', 'nature'}
{import_common_into_schema 'database-modules/nature_habitats_and_species/', 'nature'}
{import_common_into_schema 'database-modules/build_nature/', 'nature'}


--
-- Grid
--
CREATE SCHEMA grid;

-- Receptors and hexagons
{import_common_into_schema 'database-modules/grid/', 'grid'}
{import_common_into_schema 'database-modules/build_grid/', 'grid'}

-- Receptors-to lookup tables
{import_common_into_schema 'database-modules/grid_receptors_to/single-zoom-level.sql', 'grid'}
{import_common_into_schema 'database-modules/build_grid_receptors_to/', 'grid'}

-- Update the default RESULT_ZOOM_LEVELS value if desired
-- Now set to 3 so the demo builds a bit faster than building the zoom-level 1 grid (the default value)
UPDATE system.constants SET value = 3 WHERE key = 'RESULT_ZOOM_LEVELS';
