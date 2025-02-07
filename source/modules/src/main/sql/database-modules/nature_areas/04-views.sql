/*
 * assessment_area_directive_view
 * ------------------------------
 * View returning per assessment area the directives (aggregated) and design status.
 * These are properties of the directive areas of the N2000 area.
 * This information is combinated into a N2000 area property.
 * As a result, this view only works for entire N2000 areas.
 */
CREATE OR REPLACE VIEW assessment_area_directive_view AS
SELECT
	natura2000_areas.assessment_area_id,
	natura2000_directive_areas.natura2000_area_id,
	array_to_string(array_agg(DISTINCT directive_code ORDER BY directive_code), ', ') AS directive_codes,
	array_to_string(array_agg(DISTINCT directive_name ORDER BY directive_name), ', ') AS directive,
	array_to_string(array_agg(DISTINCT natura2000_directive_areas.design_status_description), ', ') AS design_status_description

	FROM natura2000_directive_areas
		INNER JOIN (
			SELECT
				natura2000_directive_area_id,
				UNNEST(string_to_array(directive_code, ', ')) AS directive_code,
				UNNEST(string_to_array(directive_name, ', ')) AS directive_name

				FROM natura2000_directive_areas
					INNER JOIN natura2000_directives USING (natura2000_directive_id)
			) AS directives USING (natura2000_directive_area_id)
		INNER JOIN natura2000_areas USING (natura2000_area_id)

	GROUP BY natura2000_areas.assessment_area_id, natura2000_area_id
;
