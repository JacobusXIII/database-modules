/*
 * countries
 * ---------
 * Table containing countries.
 * Contains a code (for use URL and such) and a more extensive name/description.
 */
CREATE TABLE countries (
	country_id integer NOT NULL,
	code text NOT NULL,
	name text NOT NULL,

	CONSTRAINT countries_pkey PRIMARY KEY (country_id),
	CONSTRAINT countries_code_unique UNIQUE (code)
);


/*
 * authorities
 * -----------
 * Table containing competent authorities.
 * Contains a code (for use URL and such), a more extensive name/description and an authority type.
 */
CREATE TABLE authorities (
	authority_id integer NOT NULL,
	country_id integer NOT NULL,
	code text NOT NULL,
	name text NOT NULL,
	type authority_type NOT NULL,

	CONSTRAINT authorities_pkey PRIMARY KEY (authority_id),
	CONSTRAINT authorities_code_unique UNIQUE (code),
	CONSTRAINT authorities_fkey_countries FOREIGN KEY (country_id) REFERENCES countries
);


/*
 * assessment_areas
 * ----------------
 * Parent table for assessment areas. Does not contain physical records itself, but is meant for inheritance.
 *
 * For NL:
 * 1..10000 = N2000 areas (in natura2000_areas) (1000+ = abroad)
 * 10001..20000 = N2000 directive areas (in natura2000_directive_areas)
 */
CREATE TABLE assessment_areas
(
	assessment_area_id integer NOT NULL,
	type assessment_area_type NOT NULL,
	name text NOT NULL,
	code text NOT NULL,
	authority_id integer NOT NULL,
	geometry geometry(MultiPolygon),

	CONSTRAINT assessment_areas_pkey PRIMARY KEY (assessment_area_id),
	CONSTRAINT assessment_areas_fkey_authorities FOREIGN KEY (authority_id) REFERENCES authorities,
	CONSTRAINT assessment_areas_code_unique UNIQUE (code)
);

CREATE INDEX idx_assessment_areas_geometry_gist ON assessment_areas USING GIST (geometry);
CREATE INDEX idx_assessment_areas_name ON assessment_areas (name);


/*
 * natura2000_areas
 * ----------------
 * Table containing nature sites (natura2000 areas).
 * The geometry used should be equal to the union of all directive areas (natura2000_directive_areas) of the same area.
 *
 * In the case of NL: the natura2000_area_id matches the official Natura 2000 area numbers as used in the netherlands.
 * In the case of UK: this table contains the nature sites.
 */
CREATE TABLE natura2000_areas
(
	natura2000_area_id integer NOT NULL,

	CONSTRAINT natura2000_areas_pkey PRIMARY KEY (natura2000_area_id)

) INHERITS (assessment_areas);

CREATE UNIQUE INDEX idx_natura2000_areas_assessment_area_id ON natura2000_areas (assessment_area_id);
CREATE INDEX idx_natura2000_areas_geometry_gist ON natura2000_areas USING GIST (geometry);
CREATE INDEX idx_natura2000_areas_name ON natura2000_areas (name);


/*
 * natura2000_area_properties
 * --------------------------
 * Table containing properties for a nature site (natura2000 area).
 *
 * @column registered_surface is the surface as it is registered in the designation decision (aanwijsbesluit)
 * @column design_status specifies the 'vaststellings-status' for the N2000 area.
 */
CREATE TABLE natura2000_area_properties (
	natura2000_area_id integer NOT NULL,
	registered_surface bigint NOT NULL,
	design_status design_status_type NOT NULL,

	CONSTRAINT natura2000_area_properties_pkey PRIMARY KEY (natura2000_area_id),
	CONSTRAINT natura2000_area_properties_fkey_natura2000_areas FOREIGN KEY (natura2000_area_id) REFERENCES natura2000_areas
);


/*
 * natura2000_directives
 * ---------------------
 * Table containing the possible directives for nature sites (natura2000 areas).
 *
 * Each directive specifies if it is a habitat directive and/or a species directive.
 * This influences in what way an area will be incorporated when it comes to relevant habitat areas.
 */
CREATE TABLE natura2000_directives
(
	natura2000_directive_id integer NOT NULL,
	directive_code text NOT NULL,
	directive_name text NOT NULL,
	habitat_directive boolean NOT NULL,
	species_directive boolean NOT NULL,

	CONSTRAINT natura2000_directives_pkey PRIMARY KEY (natura2000_directive_id),
	CONSTRAINT natura2000_directives_unique_code UNIQUE (directive_code)
);


/*
 * natura2000_directive_areas
 * --------------------------
 * Table containing the sections of the nature sites (natura2000 areas) with their own directive(s).
 */
CREATE TABLE natura2000_directive_areas
(
	natura2000_directive_area_id integer NOT NULL,
	natura2000_area_id integer NOT NULL,
	natura2000_directive_id integer NOT NULL,
	design_status_description text NOT NULL,

	CONSTRAINT natura2000_directive_areas_pkey PRIMARY KEY (natura2000_directive_area_id),
	CONSTRAINT natura2000_directive_areas_fkey_natura2000_areas FOREIGN KEY (natura2000_area_id) REFERENCES natura2000_areas,
	CONSTRAINT natura2000_directive_areas_fkey_natura2000_directives FOREIGN KEY (natura2000_directive_id) REFERENCES natura2000_directives
) INHERITS (assessment_areas);

CREATE UNIQUE INDEX idx_natura2000_directive_areas_assessment_area_id ON natura2000_directive_areas (assessment_area_id);
CREATE INDEX idx_natura2000_directive_areas_geometry_gist ON natura2000_directive_areas USING GIST (geometry);
CREATE INDEX idx_natura2000_directive_areas_name ON natura2000_directive_areas (name);
