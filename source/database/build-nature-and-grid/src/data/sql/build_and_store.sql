-- Nature - Habitats and Species
{import_common_into_schema 'database-modules/build_nature/build.sql', 'nature'}
{import_common_into_schema 'database-modules/build_nature/store.sql', 'nature'}


-- Grid - Receptors and hexagons
{import_common_into_schema 'database-modules/build_grid/load.sql', 'grid'}
{import_common_into_schema 'database-modules/build_grid/build.sql', 'grid'}
{import_common_into_schema 'database-modules/build_grid/store.sql', 'grid'}

-- Grid - Receptors-to
{import_common_into_schema 'database-modules/build_grid_receptors_to/build-single-zoom-level.sql', 'grid'}
{import_common_into_schema 'database-modules/build_grid_receptors_to/store.sql', 'grid'}
