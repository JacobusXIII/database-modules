--
-- Make sure there is only one result-zoom-level set.
--
DO
$BODY$
DECLARE
    zoom_levels int[];
BEGIN
    zoom_levels := string_to_array(system.constant('RESULT_ZOOM_LEVELS'), ',')::int[];

    IF array_length(zoom_levels, 1) <> 1 THEN
        RAISE EXCEPTION 'RESULT_ZOOM_LEVELS must contain exactly one value';
    END IF;
END
$BODY$;


-- 
-- Store Multi-zoom-level- as Single-zoom-level structure by exporting the data without the zoom-level field.
--
SELECT system.store_query(
	'grid.receptors_to_assessment_areas',
	$$ SELECT
		receptor_id,
		assessment_area_id,
		surface

		FROM receptors_to_assessment_areas

		ORDER BY
			receptor_id,
			assessment_area_id,
			surface
	$$,
	'{data_folder}/export/{tablename}_{datesuffix}.txt'
);

SELECT system.store_query(
	'grid.receptors_to_critical_deposition_areas',
	$$ SELECT
		assessment_area_id,
		type,
		critical_deposition_area_id,
		receptor_id,
		surface,
		receptor_habitat_coverage

		FROM receptors_to_critical_deposition_areas

		ORDER BY
			assessment_area_id,
			type,
			critical_deposition_area_id,
			receptor_id,
			surface,
			receptor_habitat_coverage
	$$,
	'{data_folder}/export/{tablename}_{datesuffix}.txt'
);
