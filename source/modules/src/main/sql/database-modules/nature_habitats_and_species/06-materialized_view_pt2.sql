/*
 * relevant_goal_habitats
 * ----------------------
 * Marerialized view voor het teruggeven van de table relevant_goal_habitats.
 *
 * Dit zijn de gegroepeerde relevant_habitats per goal_habitat_type_id. 
 */
CREATE MATERIALIZED VIEW relevant_goal_habitats AS
SELECT
	assessment_area_id,
	goal_habitat_type_id,
	name,
	description,
	system.weighted_avg(habitat_coverage::numeric, ST_Area(geometry)::numeric)::fraction AS coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(geometry)), 3) AS geometry

	FROM
		(SELECT
			assessment_area_id,
			goal_habitat_type_id,
			bool_or(sensitive) AS sensitive

			FROM
				-- Habitat
				(SELECT 
					assessment_area_id,
					goal_habitat_type_id

					FROM habitat_properties

					WHERE NOT (quality_goal = 'none' AND extent_goal = 'none')

				UNION

				-- Soorten
				SELECT
					assessment_area_id,
					goal_habitat_type_id

					FROM species_to_habitats

				UNION

				-- H9999 ..
				SELECT
					DISTINCT
						assessment_area_id,
						goal_habitat_type_id

						FROM relevant_habitats
							INNER JOIN habitat_type_relations USING (habitat_type_id)

				) AS all_designated

				INNER JOIN habitat_type_relations USING (goal_habitat_type_id)
				INNER JOIN habitat_type_critical_depositions_view USING (habitat_type_id)

			GROUP BY assessment_area_id, goal_habitat_type_id

		) AS designated

		INNER JOIN habitat_type_relations USING (goal_habitat_type_id)
		INNER JOIN relevant_habitats USING (assessment_area_id, habitat_type_id)		
		INNER JOIN habitat_types ON (habitat_types.habitat_type_id = designated.goal_habitat_type_id)
		
	WHERE sensitive IS TRUE

	GROUP BY assessment_area_id, goal_habitat_type_id, name, description
;

CREATE UNIQUE INDEX idx_relevant_goal_habitats_ids ON relevant_goal_habitats (assessment_area_id, goal_habitat_type_id);
CREATE INDEX idx_relevant_goal_habitats_gist ON relevant_goal_habitats USING GIST (geometry);
