SELECT system.raise_notice('Refresh materialized views @ ' || timeofday());

BEGIN; REFRESH MATERIALIZED VIEW grid.included_receptors; COMMIT;
BEGIN; REFRESH MATERIALIZED VIEW grid.critical_levels; COMMIT;
BEGIN; REFRESH MATERIALIZED VIEW grid.hexagon_type_receptors; COMMIT;
BEGIN; REFRESH MATERIALIZED VIEW grid.receptors_to_relevant_habitats; COMMIT;

SELECT system.raise_notice('Refreshing materialized views done @ ' || timeofday());
