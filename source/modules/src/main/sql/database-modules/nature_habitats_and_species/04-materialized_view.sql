/*
 * habitats
 * --------
 * Materialized view to return the habitats, 
 * a union of all habitat areas of the same habitat type within an assssment area.
 *
 * When determining the average coverage for a habitat, the surface of the individual habitat areas is used as weight.
 */
CREATE MATERIALIZED VIEW habitats AS
SELECT
	assessment_area_id,
	habitat_type_id,
	system.weighted_avg(coverage::numeric, ST_Area(habitat_areas.geometry)::numeric)::fraction AS habitat_coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(habitat_areas.geometry)), 3) AS geometry

	FROM habitat_areas

	GROUP BY assessment_area_id, habitat_type_id
;

CREATE UNIQUE INDEX idx_habitats_ids ON habitats (assessment_area_id, habitat_type_id);
CREATE INDEX idx_habitats_habitat_type_id ON habitats (habitat_type_id);
CREATE INDEX idx_habitats_gist ON habitats USING GIST (geometry);


/*
 * relevant_habitats
 * -----------------
 * Materialized view to return the relevant_habitats,
 * a union of all the relevant parts of habitat areas of the same habitat type in an assessment area.
 *
 * When determining the average coverage for a relevant habitat, the surface of the individual relevant habitat areas is used as weight.
 * When the habitat area is partly relevant, the whole area of the habitat is used as the weight.
 * This prevents the assumption that the coverage is equally spread over the entire habitat area.
 */
CREATE MATERIALIZED VIEW relevant_habitats AS
SELECT
	assessment_area_id,
	habitat_type_id,
	system.weighted_avg(habitat_areas.coverage::numeric, ST_Area(habitat_areas.geometry)::numeric)::fraction AS habitat_coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(relevant_habitat_areas.geometry)), 3) AS geometry

	FROM relevant_habitat_areas
		INNER JOIN habitat_areas USING (assessment_area_id, habitat_area_id, habitat_type_id)

	GROUP BY assessment_area_id, habitat_type_id
;

CREATE UNIQUE INDEX idx_relevant_habitats_ids ON habitats (assessment_area_id, habitat_type_id);
CREATE INDEX idx_relevant_habitats_habitat_type_id ON relevant_habitats (habitat_type_id);
CREATE INDEX idx_relevant_habitats_gist ON relevant_habitats USING GIST (geometry);


/*
 * relevant_species
 * ----------------
 * Materialized view to return the relevant_species table, 
 * a union of all the relevant parts of habitat areas related to the same species in an assessment area.
 *
 * When determining the average coverage for a relevant species, the weighted relevant habitat coverage is used.
 */
CREATE MATERIALIZED VIEW relevant_species AS
SELECT
	assessment_area_id,
	species_id,
	system.weighted_avg(habitat_coverage::numeric, ST_Area(geometry)::numeric)::fraction AS coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(geometry)), 3) AS geometry

	FROM relevant_habitats
		INNER JOIN habitat_type_relations USING (habitat_type_id)
		INNER JOIN species_to_habitats USING (assessment_area_id, goal_habitat_type_id)

	GROUP BY assessment_area_id, species_id
;

CREATE UNIQUE INDEX idx_relevant_species_ids ON relevant_species (assessment_area_id, species_id);
CREATE INDEX idx_relevant_species_gist ON relevant_species USING GIST (geometry);
