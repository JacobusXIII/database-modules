SELECT system.raise_notice('Build: receptors_to_assessment_areas @ ' || timeofday());

{multithread on: SELECT assessment_area_id FROM nature.assessment_areas ORDER BY assessment_area_id}

	-- For the executed multi thread code execution the import_common_into_schema search path schema is not set.
	-- This is the only way I could find to make this code work.
	SET search_path TO 'grid', 'public';

	INSERT INTO receptors_to_assessment_areas (receptor_id, assessment_area_id, zoom_level, surface)
	SELECT
		receptor_id,
		assessment_area_id,
		zoom_level,
		surface

		FROM build_receptors_to_assessment_areas_view
		
		WHERE assessment_area_id = {assessment_area_id}
	;

{/multithread}


SELECT system.raise_notice('Build: receptors_to_critical_deposition_areas @ ' || timeofday());

{multithread on: SELECT assessment_area_id, critical_deposition_area_type FROM nature.assessment_areas CROSS JOIN (SELECT unnest(enum_range(null::public.critical_deposition_area_type)) AS critical_deposition_area_type) AS types ORDER BY assessment_area_id, critical_deposition_area_type }

	-- For the executed multi thread code execution the import_common_into_schema search path schema is not set.
	-- This is the only way I could find to make this code work.
	SET search_path TO 'grid', 'public';

	INSERT INTO receptors_to_critical_deposition_areas (assessment_area_id, type, critical_deposition_area_id, receptor_id, zoom_level, surface, receptor_habitat_coverage)
	SELECT
		assessment_area_id,
		type,
		critical_deposition_area_id,
		receptor_id,
		zoom_level,
		surface,
		receptor_habitat_coverage

		FROM build_receptors_to_critical_deposition_areas_view
		
		WHERE
			assessment_area_id = {assessment_area_id}
			AND type = '{critical_deposition_area_type}'
	;
{/multithread}
