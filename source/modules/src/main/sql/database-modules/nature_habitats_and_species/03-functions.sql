/*
 * ae_critical_deposition_classification
 * -------------------------------------
 * Function to determine the critical deposition classification based on critical deposition value (KDW).
 * Current classification:
 * - Highly sensitive: < 1400
 * - Sensitive: 1400 <= KDW < 2400
 * - Lowly/not sensitive: >= 2400
 */
CREATE OR REPLACE FUNCTION nature.ae_critical_deposition_classification(critical_deposition posreal)
	RETURNS text AS
$BODY$
DECLARE
	result nature.critical_deposition_classification;
BEGIN
	IF (critical_deposition < 1400) THEN
		result = 'high_sensitivity';
	ELSIF (critical_deposition >= 2400) THEN
		result = 'low_sensitivity';
	ELSE
		result = 'normal_sensitivity';
	END IF;

	RETURN result::text;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;
