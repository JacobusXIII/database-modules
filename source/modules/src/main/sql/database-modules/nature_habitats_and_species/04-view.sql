/*
 * habitat_properties_view
 * -----------------------
 * View returning the properties of a habitat type in an assessment area.
 * This view uses the parent habitat type properties based on the habitat_type_relations table.
 */
CREATE OR REPLACE VIEW nature.habitat_properties_view AS
SELECT
	assessment_area_id,
	habitat_type_id,
	quality_goal,
	extent_goal

	FROM nature.habitat_properties
		INNER JOIN nature.habitat_type_relations USING (goal_habitat_type_id)
;


/*
 * designated_habitats_view
 * ------------------------
 * View to determine the designated habitat types per assessment area.
 * Relationships based on the habitat_type_relations are taken into account.
 */
CREATE OR REPLACE VIEW nature.designated_habitats_view AS
SELECT
	assessment_area_id,
	habitat_type_id

	FROM nature.habitat_properties_view

	WHERE NOT (quality_goal = 'none' AND extent_goal = 'none')
;


/*
 * habitat_type_sensitivity_view
 * -----------------------------
 * View returning the (nitrogen) sensitiveness of a habitat type.
 */
CREATE OR REPLACE VIEW nature.habitat_type_sensitivity_view AS
SELECT
	habitat_type_id,
	bool_or(sensitive) AS sensitive

	FROM nature.habitat_type_critical_levels

	GROUP BY habitat_type_id
;


/*
 * habitat_type_critical_depositions_view
 * --------------------------------------
 * View returning the critical deposition value (KDW) of a habitat type.
 */
CREATE OR REPLACE VIEW nature.habitat_type_critical_depositions_view AS
SELECT
	habitat_type_id,
	critical_level AS critical_deposition,
	sensitive

	FROM nature.habitat_type_critical_levels

	WHERE
		substance_id= 1711
		AND result_type = 'deposition'
;


/*
 * species_to_habitats_view
 * ------------------------
 * View returning for each species in which assessment area/habitat type they are present.
 * This view uses the parent habitat type based on the habitat_type_relations table.
 */
CREATE OR REPLACE VIEW nature.species_to_habitats_view AS
SELECT
	species_id,
	assessment_area_id,
	habitat_type_id

	FROM nature.species_to_habitats
		INNER JOIN nature.habitat_type_relations USING (goal_habitat_type_id)
;


/*
 * designated_species_to_habitats_view
 * -----------------------------------
 * View to determine the designated (bird) species per habitat type and assessment area.
 * Relationships based on the habitat_type_relations are taken into account.
 */
CREATE OR REPLACE VIEW nature.designated_species_to_habitats_view AS
SELECT
	species_id,
	assessment_area_id,
	habitat_type_id

	FROM nature.species_to_habitats_view
		INNER JOIN nature.designated_species USING (species_id, assessment_area_id)
;


/*
 * critical_deposition_areas_view
 * ------------------------------
 * View to collect the critical deposition areas with associated type, critical deposition value, and whether or not they are designated.
 * This includes both the set of all habitat areas and the set of relevant habitat areas.
 */
CREATE OR REPLACE VIEW nature.critical_deposition_areas_view AS
SELECT
	assessment_area_id,
	'habitat'::nature.critical_deposition_area_type AS type,
	habitat_type_id AS critical_deposition_area_id,
	name,
	description,
	FALSE AS relevant, -- These are NOT the relevant_habitats
	geometry

	FROM nature.habitats
		INNER JOIN nature.habitat_types USING (habitat_type_id)
UNION ALL
SELECT
	assessment_area_id,
	'relevant_habitat'::nature.critical_deposition_area_type AS type,
	habitat_type_id AS critical_deposition_area_id,
	name,
	description,
	TRUE AS relevant, -- These are the relevant_habitats
	geometry

	FROM nature.relevant_habitats
		INNER JOIN nature.habitat_types USING (habitat_type_id)
;


/*
 * critical_deposition_area_critical_levels_view
 * ---------------------------------------------
 * View returning the critical deposition values for critical deposition areas.
 * This view only returns records for which the habitat type is set to be 'sensitive'.
 */
CREATE OR REPLACE VIEW nature.critical_deposition_area_critical_levels_view AS
SELECT
	habitat_type_id AS critical_deposition_area_id,
	substance_id,
	result_type,
	critical_level

	FROM nature.habitat_type_critical_levels

	WHERE sensitive = TRUE
;


/*
 * habitats_view
 * -------------
 * View returning for an assessment area which habitattypes are contained within: all habitat ares that intersect with the assessment area.
 * The union of the geometries of all areas of the type is also returned.
 * Use 'assessment_area_id' in the where-clause.
 */
CREATE OR REPLACE VIEW nature.habitats_view AS
SELECT
	assessment_area_id,
	habitat_types.habitat_type_id,
	habitat_types.name,
	habitat_types.description,
	(relevant_habitats.habitat_type_id IS NOT NULL) AS relevant,
	(designated_habitats_view.habitat_type_id IS NOT NULL) AS designated,

	habitats.habitat_coverage,
	ST_Area(habitats.geometry) AS surface, -- ingetekend totaal oppervlak
	ST_Area(habitats.geometry) * habitats.habitat_coverage AS cartographic_surface, -- gekarteerd totaal oppervlak
	habitats.geometry,

	(COALESCE(relevant_habitats.habitat_coverage, 0))::real AS relevant_habitat_coverage,
	(COALESCE(ST_Area(relevant_habitats.geometry), 0))::real AS relevant_surface, -- ingetekend relevant oppervlak
	(COALESCE(ST_Area(relevant_habitats.geometry) * relevant_habitats.habitat_coverage, 0))::real AS relevant_cartographic_surface,
	relevant_habitats.geometry AS relevant_geometry

	FROM nature.assessment_areas
		INNER JOIN nature.habitats USING (assessment_area_id)
		INNER JOIN nature.habitat_types USING (habitat_type_id)
		LEFT JOIN nature.relevant_habitats USING (assessment_area_id, habitat_type_id)
		LEFT JOIN nature.designated_habitats_view USING (assessment_area_id, habitat_type_id)
;


/*
 * habitat_info_for_assessment_area_view
 * -------------------------------------
 * View returning the habitat types within an assessment area, including properties like coverage, surface and goals.
 * Used in the info-popup in Calculator when hovering over habitat type.
 * Use 'assessment_area_id' in the where-clause.
 */
CREATE OR REPLACE VIEW nature.habitat_info_for_assessment_area_view AS
SELECT
	assessment_area_id,
	habitat_type_id,
	name AS habitat_type_name,
	description AS habitat_type_description,
	designated,
	relevant,
	substance_id,
	result_type,
	critical_level,
	habitat_coverage,
	surface, -- ingetekend totaal oppervlak
	cartographic_surface, -- gekarteerd totaal oppervlak
	relevant_habitat_coverage,
	relevant_surface, -- ingetekend relevant oppervlak
	relevant_cartographic_surface, -- gekarteerd relevant oppervlak
	quality_goal,
	extent_goal

	FROM nature.habitats_view
		INNER JOIN nature.habitat_type_critical_levels USING (habitat_type_id)
		LEFT JOIN nature.habitat_properties_view USING (habitat_type_id, assessment_area_id)
;


/*
 * wms_habitats_view
 * -----------------
 * WMS view returning the habitat area(s) within an assessment area.
 * Use at least 'assessment_area_id' in the where-clause, optionally 'habitat_type_id'.
 */
CREATE OR REPLACE VIEW nature.wms_habitats_view AS
SELECT
	assessment_area_id,
	habitat_type_id,
	name,
	description,
	geometry,
	relevant_geometry

	FROM nature.habitats_view
;


/*
 * wms_habitat_areas_sensitivity_view
 * ----------------------------------
 * WMs view returning habitat areas including critical deposition classification and relevance.
 */
CREATE OR REPLACE VIEW nature.wms_habitat_areas_sensitivity_view AS
SELECT
	habitat_area_id,
	habitat_type_id,
	critical_deposition,
	nature.ae_critical_deposition_classification(critical_deposition) AS critical_deposition_classification,
	(relevant_habitat_areas.habitat_type_id IS NOT NULL) AS relevant,
	habitat_areas.geometry,
	relevant_habitat_areas.geometry AS relevant_geometry

	FROM nature.habitat_areas
		INNER JOIN nature.habitat_types USING (habitat_type_id)
		INNER JOIN nature.habitat_type_critical_depositions_view USING (habitat_type_id)
		LEFT JOIN nature.relevant_habitat_areas USING (habitat_area_id, assessment_area_id, habitat_type_id)
;
