CREATE EXTENSION postgis;

{import_common 'database-build/public/'}
{import_common 'database-build/essentials.sql'}
{import_common 'database-build/toolbox.sql'}

{import_common 'database-modules/aerius-general/'}

CREATE SCHEMA nature;

{import_common_into_schema 'database-modules/nature_areas/', 'nature'}
{import_common_into_schema 'database-modules/nature_habitats_and_species/', 'nature'}
{import_common_into_schema 'database-modules/build_nature/', 'nature'}

-- Override setup.build_relevant_habitat_areas_view to ignore directive and process every area, as UK doesn't differentiate between habitat and species.
-- Also ignore design status, as that is not something used in UK, so no point in taken it into account
-- Supplied data contains false for both habitat_directive and bird_directive, but we still want to generate stuff
CREATE OR REPLACE VIEW nature.build_relevant_habitat_areas_view AS
WITH natura2000_directive_area_properties AS (
	SELECT
		natura2000_directive_area_id,
		natura2000_area_id AS assessment_area_id,
		geometry

		FROM nature.natura2000_directive_areas
)
SELECT * FROM
	(SELECT
		assessment_area_id,
		habitat_area_id,
		habitat_type_id,
		coverage,
		ST_CollectionExtract(ST_Multi(ST_Union(ST_Intersection(natura2000_directive_area_geometry, habitat_area_geometry))), 3) AS geometry

		FROM
			-- Nitrogen-sensitive designated habitat within an area
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
					INNER JOIN nature.habitat_type_sensitivity_view USING (habitat_type_id)
					INNER JOIN natura2000_directive_area_properties USING (assessment_area_id)
					INNER JOIN nature.habitat_type_relations USING (habitat_type_id)
					LEFT JOIN nature.habitat_properties USING (goal_habitat_type_id, assessment_area_id)
					LEFT JOIN nature.designated_habitats_view USING (habitat_type_id, assessment_area_id)

				WHERE
					sensitive IS TRUE
					AND designated_habitats_view.habitat_type_id IS NOT NULL

		) AS relevant_habitats

		GROUP BY assessment_area_id, habitat_area_id, habitat_type_id, coverage
	) AS relevant_habitat_areas

	WHERE NOT ST_IsEmpty(geometry)
;
