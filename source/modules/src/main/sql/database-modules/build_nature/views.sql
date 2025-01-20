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
CREATE OR REPLACE VIEW build_relevant_habitat_areas_view AS
WITH natura2000_directive_area_properties AS (
	SELECT
		natura2000_directive_area_id,
		natura2000_area_id AS assessment_area_id,
		species_directive,
		habitat_directive,
		design_status AS natura2000_directive_area_design_status,
		geometry

		FROM natura2000_directive_areas
			INNER JOIN natura2000_directives USING (natura2000_directive_id)
			INNER JOIN natura2000_area_properties USING (natura2000_area_id)
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

				FROM habitat_areas
					INNER JOIN habitat_types USING (habitat_type_id)
					INNER JOIN habitat_type_sensitivity_view USING (habitat_type_id)
					INNER JOIN natura2000_directive_area_properties USING (assessment_area_id)
					INNER JOIN habitat_type_relations USING (habitat_type_id)
					LEFT JOIN habitat_properties USING (goal_habitat_type_id, assessment_area_id)
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

				FROM habitat_areas
					INNER JOIN habitat_type_sensitivity_view USING (habitat_type_id)
					INNER JOIN natura2000_directive_area_properties USING (assessment_area_id)
					INNER JOIN designated_species_to_habitats_view USING (assessment_area_id, habitat_type_id)
					INNER JOIN species USING (species_id)
					INNER JOIN species_properties USING (species_id, assessment_area_id)

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


/*
 * build_habitats_view
 * -------------------
 * View to fill the habitats table, a union of all habitat areas of the same habitat type within an assssment area.
 *
 * When determining the average coverage for a habitat, the surface of the individual habitat areas is used as weight.
 */
CREATE OR REPLACE VIEW build_habitats_view AS
SELECT
	assessment_area_id,
	habitat_type_id,
	system.weighted_avg(coverage::numeric, ST_Area(habitat_areas.geometry)::numeric)::fraction AS habitat_coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(habitat_areas.geometry)), 3) AS geometry

	FROM habitat_areas

	GROUP BY assessment_area_id, habitat_type_id
;


/*
 * build_relevant_habitats_view
 * ----------------------------
 * View to fill the relevant_habitats table, a union of all the relevant parts of habitat areas of the same habitat type in an assessment area.
 *
 * When determining the average coverage for a relevant habitat, the surface of the individual relevant habitat areas is used as weight.
 * When the habitat area is partly relevant, the whole area of the habitat is used as the weight.
 * This prevents the assumption that the coverage is equally spread over the entire habitat area.
 */
CREATE OR REPLACE VIEW build_relevant_habitats_view AS
SELECT
	assessment_area_id,
	habitat_type_id,
	system.weighted_avg(habitat_areas.coverage::numeric, ST_Area(habitat_areas.geometry)::numeric)::fraction AS habitat_coverage,
	ST_CollectionExtract(ST_Multi(ST_Union(relevant_habitat_areas.geometry)), 3) AS geometry

	FROM relevant_habitat_areas
		INNER JOIN habitat_areas USING (assessment_area_id, habitat_area_id, habitat_type_id)

	GROUP BY assessment_area_id, habitat_type_id
;
