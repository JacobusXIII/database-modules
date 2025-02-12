SELECT system.raise_notice('Build: geometry_of_interests @ ' || timeofday());
BEGIN; SELECT grid.ae_build_geometry_of_interests(); COMMIT;

SELECT system.raise_notice('Build: hexagons and receptors @ ' || timeofday());
BEGIN; SELECT grid.ae_build_hexagons_and_receptors(); COMMIT;
