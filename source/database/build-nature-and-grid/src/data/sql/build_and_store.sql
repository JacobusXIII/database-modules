-- Nature - Habitats and Species
{import_common 'database-modules/build_nature/build.sql'}
{import_common 'database-modules/build_nature/store.sql'}


-- Grid - Receptors and hexagons
{import_common 'database-modules/build_grid/load.sql'}
{import_common 'database-modules/build_grid/build.sql'}
{import_common 'database-modules/build_grid/store.sql'}

-- Grid - Receptors-to
{import_common 'database-modules/build_grid_receptors_to/build-single-zoom-level.sql'}
{import_common 'database-modules/build_grid_receptors_to/store.sql'}
