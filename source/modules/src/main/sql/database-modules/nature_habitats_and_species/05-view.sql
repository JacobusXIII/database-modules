/*
 * habitat_type_critical_depositions_view
 * --------------------------------------
 * View returning the critical deposition value (KDW) of a habitat type.
 */
CREATE OR REPLACE VIEW habitat_type_critical_depositions_view AS
SELECT
	habitat_type_id,
	critical_level AS critical_deposition,
	sensitive

	FROM habitat_type_critical_levels

	WHERE
		substance_id = 1711
		AND result_type = 'deposition'
;


/*
 * relevant_goal_habitat_types_view
 * --------------------------------
 * View to collect the relevant goal habitat types with name and description per assessment areas.
 * This includes all Habitat-, Species- and H9999- goal habitat types.
 */
CREATE OR REPLACE VIEW relevant_goal_habitat_types_view AS
SELECT
	assessment_area_id,
	goal_habitat_type_id,
	name,
	description

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

		INNER JOIN habitat_types ON (habitat_types.habitat_type_id = designated.goal_habitat_type_id)

	WHERE sensitive IS TRUE
;
