add_build_constants

cluster_tables

# Uncomment the (single) test you want to run.
# Due to the `recurring or circular {import_common} detection` we cannot run all test during one single build.
run_sql "test_grid_and_nature.sql"
# run_sql "test_build_nature.sql"

synchronize_serials

$do_run_unit_tests = true unless has_build_flag :no_unittest
$do_validate_contents = true if has_build_flag :validate
$do_create_summary = true if has_build_flag :summary
