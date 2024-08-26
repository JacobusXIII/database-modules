/*
 * authority_type
 * --------------
 * The typ of an authority.
 * Be aware that the order of this enum also dictates how the entries in the authorities table are sorted in the UI (for example in a dropdown box).
 */
CREATE TYPE nature.authority_type AS ENUM
	('unknown', 'province', 'ministry', 'foreign');

/*
 * design_status_type
 * ------------------
 * The type of the design status (status van een doelstelling) of a habitat type or species.
 *
 */
CREATE TYPE nature.design_status_type AS ENUM
	('aanmelding', 'ontwerp', 'definitief', 'irrelevant');


/*
 * assessment_area_type
 * --------------------
 * The type of an assesment area.
 */
CREATE TYPE nature.assessment_area_type AS ENUM
	('natura2000_area', 'natura2000_directive_area');
