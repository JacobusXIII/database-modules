/*
 * habitat_types
 * -------------
 * Table containing the habitat types, identified by the name column and with an additional description.
 */
CREATE TABLE nature.habitat_types
(
	habitat_type_id integer NOT NULL,
	name text NOT NULL,
	description text NOT NULL,

	CONSTRAINT habitat_types_pkey PRIMARY KEY (habitat_type_id)
);

CREATE UNIQUE INDEX idx_habitat_types_name ON nature.habitat_types (name);


/*
 * habitat_type_critical_levels
 * ----------------------------
 * Table containing the critical levels for the habitat types per substance and emission result type.
 * NOTE: For critical nitrogen deposition (KDW) a value has to be used for substance ID 1711 and result type "deposition".
 */
CREATE TABLE nature.habitat_type_critical_levels (
	habitat_type_id integer NOT NULL,
	substance_id smallint NOT NULL,
	result_type emission_result_type NOT NULL,
	critical_level posreal NULL,
	sensitive boolean NOT NULL DEFAULT FALSE,

	CONSTRAINT habitat_type_critical_levels_pkey PRIMARY KEY (habitat_type_id, substance_id, result_type),
	CONSTRAINT habitat_type_critical_levels_fkey_habitat_types FOREIGN KEY (habitat_type_id) REFERENCES nature.habitat_types
);


/*
 * habitat_properties
 * ------------------
 * Table containing the properties of the goal/designated habitat types per assessment area, along with the status.
 * @column quality_goal The goal for quality (doelstelling kwaliteit).
 * @column extent_goal The goal for extent/surface (doelstelling oppervlakte).
 * @column design_status The status of this habitat type (vaststellings status).
 */
CREATE TABLE nature.habitat_properties (
	goal_habitat_type_id integer NOT NULL,
	assessment_area_id integer NOT NULL,
	quality_goal nature.habitat_goal_type NOT NULL,
	extent_goal nature.habitat_goal_type NOT NULL,
	design_status nature.design_status_type NOT NULL CHECK (design_status <> 'irrelevant'),

	CONSTRAINT habitat_properties_pkey PRIMARY KEY (goal_habitat_type_id, assessment_area_id),
	CONSTRAINT habitat_properties_fkey_habitat_types FOREIGN KEY (goal_habitat_type_id) REFERENCES nature.habitat_types (habitat_type_id)
);


/*
 * habitat_type_relations
 * ----------------------
 * Table containing the relations between habitat types.
 * Habitat types can be sub-types of a goal/designated habitat type.
 * For instance, H1330A and ZGH1330A, which are both part of designated habitat type H1330A.
 * This parent-child relation is kept in this table.
 * A habitat type can only have 1 goal habitat type. Most habitat types have themselves as the goal habitat type.
 */
CREATE TABLE nature.habitat_type_relations
(
	habitat_type_id integer NOT NULL UNIQUE,
	goal_habitat_type_id integer NOT NULL,

	CONSTRAINT habitat_type_relations_pkey PRIMARY KEY (habitat_type_id, goal_habitat_type_id),
	CONSTRAINT habitat_type_relations_fkey_habitat_types FOREIGN KEY (habitat_type_id) REFERENCES nature.habitat_types,
	CONSTRAINT habitat_type_relations_fkey_goal_habitat_types FOREIGN KEY (goal_habitat_type_id) REFERENCES nature.habitat_types (habitat_type_id)
);


/*
 * habitat_areas
 * -------------
 * Table containing the habitat areas per assessment area. A habitat area has a habitat type.
 *
 * @column coverage The coverage of the habitat over the area (Dekkingsgraad). This factor is used to determine the cartographic surface.
 */
CREATE TABLE nature.habitat_areas
(
	assessment_area_id integer NOT NULL,
	habitat_area_id integer NOT NULL,
	habitat_type_id integer NOT NULL,
	coverage fraction NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT habitat_areas_pkey PRIMARY KEY (habitat_area_id),
	CONSTRAINT habitat_areas_fkey_habitat_types FOREIGN KEY (habitat_type_id) REFERENCES nature.habitat_types
);

CREATE INDEX idx_habitat_areas_geometry_gist ON nature.habitat_areas USING GIST (geometry);
CREATE INDEX idx_habitat_areas_assessment_area_id ON nature.habitat_areas (assessment_area_id);
CREATE INDEX idx_habitat_areas_habitat_type_id ON nature.habitat_areas (habitat_type_id);


/*
 * relevant_habitat_areas
 * ----------------------
 * Table containing the relevant (parts of) habitat areas per assessment areas.
 * 
 * A habitat area either is or isn't relevant, but at the borders of assessment areas it can also be partly relevant.
 * In that case the geometry is the intersection of the assessment area and habitat area.
 * 
 * @column coverage Coverage of the whole habitat area, equal to {@link habitat_areas}.
 */
CREATE TABLE nature.relevant_habitat_areas
(
	assessment_area_id integer NOT NULL,
	habitat_area_id integer NOT NULL,
	habitat_type_id integer NOT NULL,
	coverage fraction NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT relevant_habitat_areas_pkey PRIMARY KEY (habitat_area_id),
	CONSTRAINT relevant_habitat_areas_fkey_habitat_types FOREIGN KEY (habitat_type_id) REFERENCES nature.habitat_types
);

CREATE INDEX idx_relevant_habitat_areas_geometry_gist ON nature.relevant_habitat_areas USING GIST (geometry);
CREATE INDEX idx_relevant_habitat_areas_assessment_area_id ON nature.relevant_habitat_areas (assessment_area_id);
CREATE INDEX idx_relevant_habitat_areas_habitat_type_id ON nature.relevant_habitat_areas (habitat_type_id);


/*
 * habitats
 * --------
 * Table containing combined habitat areas per assessment area and habitat type.
 * The geometry is the combination of all individual areas of the habitat type within the assessment area.
 *
 * @column habitat_coverage Average coverage for this habitat. Calculated based on the average of the individual habitat areas, 
 * weighted by surface of each area.
 */
CREATE TABLE nature.habitats
(
	assessment_area_id integer NOT NULL,
	habitat_type_id integer NOT NULL,
	habitat_coverage fraction NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT habitats_pkey PRIMARY KEY (assessment_area_id, habitat_type_id),
	CONSTRAINT habitats_fkey_habitat_types FOREIGN KEY (habitat_type_id) REFERENCES nature.habitat_types
);

CREATE INDEX idx_habitats_geometry_gist ON nature.habitats USING GIST (geometry);
CREATE INDEX idx_habitats_habitat_type_id ON nature.habitats (habitat_type_id);


/*
 * relevant_habitats
 * -----------------
 * Table containing relevant (parts of) combined habitat areas.
 *
 * @column habitat_coverage Average coverage for this habitat. Calculated based on the average of the individual habitat areas, 
 * weighted by surface of each area. For partially relevant habitat areas, the full surface of the area is used as the weight.
 */
CREATE TABLE nature.relevant_habitats
(
	assessment_area_id integer NOT NULL,
	habitat_type_id integer NOT NULL,
	habitat_coverage fraction NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT relevant_habitats_pkey PRIMARY KEY (assessment_area_id, habitat_type_id),
	CONSTRAINT relevant_habitats_fkey_habitat_types FOREIGN KEY (habitat_type_id) REFERENCES nature.habitat_types
);

CREATE INDEX idx_relevant_habitats_geometry_gist ON nature.relevant_habitats USING GIST (geometry);
CREATE INDEX idx_relevant_habitats_habitat_type_id ON nature.relevant_habitats (habitat_type_id);


/*
 * species
 * -------
 * Table containing species that can be present in a habitat.
 * This can be habitat species, breeding bird species and non breeding bird species.
 * A bird species can be present as both breeding and non-breeding in this table, as for some areas it is considered breeding while for others it is not.
 */
CREATE TABLE nature.species
(
	species_id integer NOT NULL,
	name text NOT NULL,
	description text NOT NULL,
	species_type nature.species_type NOT NULL,

	CONSTRAINT species_pkey PRIMARY KEY (species_id)
);

CREATE UNIQUE INDEX idx_species_name ON nature.species (name, species_type);


/*
 * species_properties
 * ------------------
 * Table containing properties of designated species per assessment areas.
 * Contains the goals for each species, including the status:
 * Goal quality habitat, goal surface habitat, goal population.
 * The population goal for non breeding bird species is supplied as text. The population_goal must be 'specified' in that case.
 * In all other cases and goal types the goal shouldn't be 'specified'.
 */
CREATE TABLE nature.species_properties (
	species_id integer NOT NULL,
	assessment_area_id integer NOT NULL,
	quality_goal nature.habitat_goal_type NOT NULL CHECK (quality_goal <> 'specified'),
	extent_goal nature.habitat_goal_type NOT NULL CHECK (extent_goal <> 'specified'),
	population_goal nature.habitat_goal_type NOT NULL
		CHECK ((population_goal <> 'specified' AND population_goal_description IS NULL) OR (population_goal = 'specified' AND population_goal_description IS NOT NULL)),
	population_goal_description text, -- TODO: need some refactoring
	design_status nature.design_status_type NOT NULL CHECK (design_status <> 'irrelevant'),

	CONSTRAINT species_properties_pkey PRIMARY KEY (species_id, assessment_area_id),
	CONSTRAINT species_properties_fkey_species FOREIGN KEY (species_id) REFERENCES nature.species
);


/*
 * designated_species
 * ------------------
 * Table containing designated species per assessment areas.
 */
CREATE TABLE nature.designated_species
(
	species_id integer NOT NULL,
	assessment_area_id integer NOT NULL,

	CONSTRAINT designated_species_pkey PRIMARY KEY (species_id, assessment_area_id),
	CONSTRAINT designated_species_fkey_assessment_areas FOREIGN KEY (assessment_area_id) REFERENCES nature.natura2000_areas (assessment_area_id), -- Currently limited to N2000. Can't reference base table 'assessment_areas'.
	CONSTRAINT designated_species_fkey_species FOREIGN KEY (species_id) REFERENCES nature.species
);


/*
 * species_to_habitats
 * -------------------
 * Table containing the species that can be present in a habitat type.
 */
CREATE TABLE nature.species_to_habitats
(
	species_id integer NOT NULL,
	assessment_area_id integer NOT NULL,
	goal_habitat_type_id integer NOT NULL,

	CONSTRAINT species_to_habitats_pkey PRIMARY KEY (species_id, assessment_area_id, goal_habitat_type_id),
	CONSTRAINT species_to_habitats_fkey_species FOREIGN KEY (species_id) REFERENCES nature.species,
	CONSTRAINT species_to_habitats_fkey_assessment_areas FOREIGN KEY (assessment_area_id) REFERENCES nature.natura2000_areas (assessment_area_id), -- Currently limited to N2000. Can't reference base table 'assessment_areas'.
	CONSTRAINT species_to_habitats_fkey_habitat_types FOREIGN KEY (goal_habitat_type_id) REFERENCES nature.habitat_types (habitat_type_id)
);
