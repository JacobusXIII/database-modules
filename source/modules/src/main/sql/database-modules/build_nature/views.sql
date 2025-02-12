/*
 * designated_habitats_view
 * ------------------------
 * View to determine the designated habitat types per assessment area.
 * Relationships based on the habitat_type_relations are taken into account.
 */
CREATE OR REPLACE VIEW designated_habitats_view AS
SELECT
	assessment_area_id,
	habitat_type_id

	FROM nature.habitat_properties
 		INNER JOIN nature.habitat_type_relations USING (goal_habitat_type_id)

	WHERE NOT (quality_goal = 'none' AND extent_goal = 'none')
;


/*
 * habitat_type_sensitivity_view
 * -----------------------------
 * View returning the (nitrogen) sensitiveness of a habitat type.
 */
CREATE OR REPLACE VIEW habitat_type_sensitivity_view AS
SELECT
	habitat_type_id,
	bool_or(sensitive) AS sensitive

	FROM nature.habitat_type_critical_levels

	GROUP BY habitat_type_id
;


/*
 * designated_species_to_habitats_view
 * -----------------------------------
 * View to determine the designated (bird) species per habitat type and assessment area.
 * Relationships based on the habitat_type_relations are taken into account.
 */
CREATE OR REPLACE VIEW designated_species_to_habitats_view AS
SELECT
	species_id,
	assessment_area_id,
	habitat_type_id

	FROM nature.species_to_habitats
		INNER JOIN nature.habitat_type_relations USING (goal_habitat_type_id)
		INNER JOIN nature.designated_species USING (species_id, assessment_area_id)
;


/*
 * build_relevant_habitat_areas_view
 * ---------------------------------
 * View to fill the relevant_habitat_areas table, based on habitat_areas.
 *
 * The following two situations are relevant:
 * - Nitrogen sensitive designated habitat (or H9999) within a habitat directive area.
 * - Designated habitat- or birdspecies within a nitrogen sensitve habitat area within a habitat or species directive area.
 *
 * Only the relevant part of the geometry is keept, which would be the intersection between N2000 directive area and habitat area that match these conditions.
 *
 * As well as these conditions, the N2000 directive areas, habitats and species should have the correct design status.
 * When the directive area is in the definitive ('definitief') state,
 * the habitat area should also be 'definitief', or at least 1 of the species in the habitat should be 'definitief'.
 * When the directive area is in the design ('ontwerp') status, then the habitats or species are not required to be 'definitief'.
 */
CREATE OR REPLACE VIEW nature.build_relevant_habitat_areas_view AS
WITH natura2000_directive_area_properties AS (
	SELECT
		natura2000_directive_area_id,
		natura2000_area_id AS assessment_area_id,
		species_directive,
		habitat_directive,
		design_status AS natura2000_directive_area_design_status,
		geometry

		FROM nature.natura2000_directive_areas
			INNER JOIN nature.natura2000_directives USING (natura2000_directive_id)
			INNER JOIN nature.natura2000_area_properties USING (natura2000_area_id)
)
SELECT * FROM
	(SELECT
		assessment_area_id,
		habitat_area_id,
		habitat_type_id,
		coverage,
		ST_CollectionExtract(ST_Multi(ST_Union(ST_Intersection(natura2000_directive_area_geometry, habitat_area_geometry))), 3) AS geometry

		FROM
			-- Nitrogen-sensitive designated habitat (or H9999) within a HR-area, with the correct design status
			(SELECT
				assessment_area_id,
				habitat_area_id,
				habitat_type_id,
				natura2000_directive_area_id,
				coverage,
				natura2000_directive_area_properties.geometry AS natura2000_directive_area_geometry,
				habitat_areas.geometry AS habitat_area_geometry

				FROM nature.habitat_areas
					INNER JOIN nature.habitat_types USING (habitat_type_id)
					INNER JOIN habitat_type_sensitivity_view USING (habitat_type_id)
					INNER JOIN natura2000_directive_area_properties USING (assessment_area_id)
					INNER JOIN nature.habitat_type_relations USING (habitat_type_id)
					LEFT JOIN nature.habitat_properties USING (goal_habitat_type_id, assessment_area_id)
					LEFT JOIN designated_habitats_view USING (habitat_type_id, assessment_area_id)

				WHERE
					sensitive IS TRUE
					AND habitat_directive IS TRUE
					AND (designated_habitats_view.habitat_type_id IS NOT NULL
						OR habitat_types.name ILIKE 'H9999%')
					AND (natura2000_directive_area_design_status = 'ontwerp'
						OR (natura2000_directive_area_design_status = 'definitief' AND habitat_properties.design_status = 'definitief')
						OR habitat_types.name ILIKE 'H9999%')
			UNION

			-- Designated habitat or bird species within a nitrogen sensitve habitat area, within a habitat or species directive area, with the correct design status
			SELECT
				assessment_area_id,
				habitat_area_id,
				habitat_type_id,
				natura2000_directive_area_id,
				coverage,
				natura2000_directive_area_properties.geometry AS natura2000_directive_area_geometry,
				habitat_areas.geometry AS habitat_area_geometry

				FROM nature.habitat_areas
					INNER JOIN habitat_type_sensitivity_view USING (habitat_type_id)
					INNER JOIN natura2000_directive_area_properties USING (assessment_area_id)
					INNER JOIN designated_species_to_habitats_view USING (assessment_area_id, habitat_type_id)
					INNER JOIN nature.species USING (species_id)
					INNER JOIN nature.species_properties USING (species_id, assessment_area_id)

				WHERE
					sensitive IS TRUE
					AND ((species_type IN ('breeding_bird_species', 'non_breeding_bird_species') AND species_directive IS TRUE)
						OR (species_type = 'habitat_species' AND habitat_directive IS TRUE))
					AND (natura2000_directive_area_design_status = 'ontwerp'
						OR (natura2000_directive_area_design_status = 'definitief' AND species_properties.design_status = 'definitief'))

			) AS relevant_habitats

		GROUP BY assessment_area_id, habitat_area_id, habitat_type_id, coverage
	) AS relevant_habitat_areas

	WHERE NOT ST_IsEmpty(geometry)
;
