/*
 * ae_get_srid
 * -----------
 * Function returning the default SRID value.
 */
CREATE OR REPLACE FUNCTION ae_get_srid()
	RETURNS integer AS
$BODY$
	SELECT system.constant('SRID')::integer;
$BODY$
LANGUAGE sql IMMUTABLE;
