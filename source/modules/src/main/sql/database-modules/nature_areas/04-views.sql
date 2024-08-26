/*
 * assessment_area_directive_view
 * ------------------------------
 * View returning per assessment area the directives (aggregated) and design status).
 * These are properties of the directive areas of the N2000 area.
 * This information is combinated into a N2000 area property.
 * As a result, this view only works for entire N2000 areas.
 */
CREATE OR REPLACE VIEW nature.assessment_area_directive_view AS
SELECT
	natura2000_areas.assessment_area_id,
	natura2000_directive_areas.natura2000_area_id,
	array_to_string(array_agg(DISTINCT directive_code ORDER BY directive_code), ', ') AS directive_codes,
	array_to_string(array_agg(DISTINCT directive_name ORDER BY directive_name), ', ') AS directive,
	array_to_string(array_agg(DISTINCT natura2000_directive_areas.design_status_description), ', ') AS design_status_description

	FROM nature.natura2000_directive_areas
		INNER JOIN (
			SELECT natura2000_directive_area_id, UNNEST(string_to_array(directive_code, ', ')) AS directive_code, UNNEST(string_to_array(directive_name, ', ')) AS directive_name
				FROM nature.natura2000_directive_areas
					INNER JOIN nature.natura2000_directives USING (natura2000_directive_id)
			) AS directives USING (natura2000_directive_area_id)
		INNER JOIN nature.natura2000_areas USING (natura2000_area_id)

	GROUP BY natura2000_areas.assessment_area_id, natura2000_area_id
;


/*
 * natura2000_area_info_view
 * -------------------------
 * View returning general information about the N2000 areas.
 * Use 'assessment_area_id', 'natura2000_area_id' or ST_Intersects(ST_SetSRID(ST_Point(218928, 486793), ae_get_srid()), geometry) in the where-clause.
 */
CREATE OR REPLACE VIEW nature.natura2000_area_info_view AS
SELECT
	assessment_area_id,
	natura2000_area_id,
	natura2000_areas.name,
	assessment_area_directive_view.directive,
	assessment_area_directive_view.directive_codes,
	assessment_area_directive_view.design_status_description,
	authorities.name AS authority,
	COALESCE(registered_surface, ROUND(ST_Area(natura2000_areas.geometry))::bigint) AS surface,
	Box2D(natura2000_areas.geometry) AS boundingbox,
	natura2000_areas.geometry

	FROM nature.natura2000_areas
		INNER JOIN nature.assessment_area_directive_view USING (assessment_area_id, natura2000_area_id)
		INNER JOIN nature.authorities USING (authority_id)
		LEFT JOIN nature.natura2000_area_properties USING (natura2000_area_id)
;


/*
 * wms_nature_areas_view
 * ---------------------
 * WMS view returning the natura2000 directive areas, including name.
 * Selectie van natura2000_directive_areas (inclusief naam).
 */
CREATE OR REPLACE VIEW nature.wms_nature_areas_view AS
SELECT
	natura2000_areas.assessment_area_id,
	country_id,
	directive_code,
	directive_name,
	design_status_description,
	natura2000_areas.name,
	natura2000_directive_areas.geometry

	FROM nature.natura2000_directive_areas
		INNER JOIN nature.natura2000_directives USING (natura2000_directive_id)
		INNER JOIN nature.authorities USING (authority_id)
		INNER JOIN nature.natura2000_areas USING (natura2000_area_id)
;
