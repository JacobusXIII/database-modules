# Database Modules

## Description
The `database-modules` is a repository for all common database objects (SQL structure) and data (loading dbdata files) bundled into modules for reuse.

## Standards 
* The database objects and data of the modules should be stable. These may only be changed in exceptional circumstances.
* Modules should be the smallest logical group of database objects and data.
* Module names should start with the recommended schema name or `aerius` if the schema is fixed or irrelevant.
* Module names may not contain dashes, only letters and underscores are allowed.
* It is not mandatory to load a module in its entirety. This can be taken into account in the design of the file structure. An example is the nature dataset where most of the dbdata files have been supplied and some have been derived from the supplied data to speed up the database build process.
* Add only NL data. In contrast to UK only NL reuses a lot of data in different projects.
* Dbdata files should have the recommended schema name as prefix. E.g. `nature.` or `grid.`.
* Using `import_common_into_schema` you can choose the schema where the database objects or object data will be added to. But there really must be a good reason to deviate from the recommended schema name. Using `import_common` the database objects or data will be added to the `public` schema.

## Current modules

### Aerius_general
Some common AERIUS functionality that is too AERIUS specific for the [`database-build`](https://github.com/aerius/database-build) common modules.

### Aerius_constants
The default AERIUS constants.

### Nature_areas
Natura2000 areas and their properties like geometry, authority and directive.

### Nature_areas_and_species
Habitats and their properties like the conservation goals, critical load and the species present.
In this module it is possible to load only the supplied data through `supplied_<dataset_year>.sql`, or the entire dataset through `dataset_<dataset_year>.sql>` including the derived (generated) data.

### Grid
Just receptors and hexagons.

### Grid_receptors_to
The common receptors_to lookup tables. There are two variants of the lookup tables. Besides the single zoom level implementation there is also a multi-zoom level implementation for when there are calculation results for multiple zoom levels (and the zoom level is part of the primary key).
Select the desired variant, in the module, by importing the specific sql.
Currently, data has only been added for the single zoom level variant.

### Build_nature
All the functionality for generating and storing the derived data.

### Build_grid
All the functionality for generating and storing the receptors and hexagons.

### Build_grid_receptors_to
All the functionality for generating and storing the receptors_to lookup tables.
