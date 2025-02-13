/*
 * receptors_to_assessment_areas
 * -----------------------------
 * Table linking receptors and assessment areas (mostly natura2000 areas) with the intersected surface.
 * The link is determined based on the hexagon at zoom level 1 corresponding to the receptor.
 */
CREATE TABLE receptors_to_assessment_areas
(
	receptor_id integer NOT NULL,
	assessment_area_id integer NOT NULL,
	zoom_level smallint NOT NULL,
	surface posreal NOT NULL,

	CONSTRAINT receptors_to_assessment_areas_pkey PRIMARY KEY (receptor_id, assessment_area_id, zoom_level),
	CONSTRAINT receptors_to_assessment_areas_fkey_receptors FOREIGN KEY (receptor_id) REFERENCES receptors
);

CREATE INDEX idx_receptors_to_assessment_areas_assessment_area_id ON receptors_to_assessment_areas (assessment_area_id);


/*
 * receptors_to_critical_deposition_areas
 * --------------------------------------
 * Table linking hexagons (by receptor_id), critical deposition areas and assessment areas (mostly natura2000 areas) with the intersected surface
 * and corresponding coverage of that critical deposition area.
 *
 * @column surface Area of the intersection of the hexagon and the critical deposition area.
 * @column receptor_habitat_coverage Average coverage of the critical deposition area on this receptor.
 * The coverage of all (relevant) habitat types that intersect with the hexagon is weighted according to the intersection surface, and averaged.
 * By multiplying the receptor_habitat_coverage value with the surface value, a valid cartographic surface is determined for this combination of receptor and critical deposition area.
 */
CREATE TABLE receptors_to_critical_deposition_areas
(
	assessment_area_id integer NOT NULL,
	type nature.critical_deposition_area_type NOT NULL,
	critical_deposition_area_id integer NOT NULL,
	receptor_id integer NOT NULL,
	zoom_level smallint NOT NULL,
	surface posreal NOT NULL,
	receptor_habitat_coverage posreal NOT NULL,

	CONSTRAINT receptors_to_critical_deposition_areas_pkey PRIMARY KEY (assessment_area_id, type, critical_deposition_area_id, receptor_id, zoom_level),
	CONSTRAINT receptors_to_critical_deposition_areas_fkey_receptors FOREIGN KEY (receptor_id) REFERENCES receptors
);

CREATE INDEX idx_receptors_to_critical_deposition_areas ON receptors_to_critical_deposition_areas (receptor_id);


/*
 * receptors_to_relevant_habitats
 * ------------------------------
 * Materialized view linking relevant habitats and hexagons (by receptor_id).
 *
 * @column cartographic_surface Surface for which the coverage is taken into account alongside the intersection of hexagon and critical deposition area.
 */
CREATE MATERIALIZED VIEW receptors_to_relevant_habitats AS
SELECT 
	assessment_area_id, 
	critical_deposition_area_id, 
	receptor_id,
	zoom_level,
	surface * receptor_habitat_coverage AS cartographic_surface
	
	FROM grid.receptors_to_critical_deposition_areas
	
	WHERE type = 'relevant_habitat'
;

CREATE UNIQUE INDEX idx_receptors_to_relevant_habitats_ids ON receptors_to_relevant_habitats (assessment_area_id, critical_deposition_area_id, receptor_id, zoom_level);
CREATE INDEX idx_receptors_to_relevant_habitats ON receptors_to_relevant_habitats (receptor_id);
