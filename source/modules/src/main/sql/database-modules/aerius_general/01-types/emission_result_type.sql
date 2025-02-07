/*
 * emission_result_type
 * --------------------
 * Enum type for indications what type an emission result is.
 */
CREATE TYPE emission_result_type AS ENUM
	('concentration', 'direct_concentration', 'deposition', 'exceedance_days', 'exceedance_hours', 'dry_deposition', 'wet_deposition');
