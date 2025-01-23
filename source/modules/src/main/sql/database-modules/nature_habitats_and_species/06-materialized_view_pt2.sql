/*
 * relevant_goal_habitats
 * ----------------------
 * Materialized view to return the relevant_goal_habitats table, 
 * a union of all the relevant parts of habitat areas related to the same goal habitat type in an assessment area.
 *
 * When determining the average coverage for a relevant goal habitat, the weighted relevant habitat coverage is used.
 */
CREATE MATERIALIZED VIEW relevant_goal_habitats AS
SELECT
	assessment_area_id,
	goal_habitat_type_id,
	system.weighted_avg(habitat_coverage::numeric, ST_Area(geometry)::numeric)::fraction AS coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(geometry)), 3) AS geometry

	FROM relevant_habitats
		INNER JOIN habitat_type_relations USING (habitat_type_id)
		INNER JOIN relevant_goal_habitat_types_view USING (assessment_area_id, goal_habitat_type_id)

	GROUP BY assessment_area_id, goal_habitat_type_id
;

CREATE UNIQUE INDEX idx_relevant_goal_habitats_ids ON relevant_goal_habitats (assessment_area_id, goal_habitat_type_id);
CREATE INDEX idx_relevant_goal_habitats_gist ON relevant_goal_habitats USING GIST (geometry);
