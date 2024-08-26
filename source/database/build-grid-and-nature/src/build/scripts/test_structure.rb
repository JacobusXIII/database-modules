clear_log

default_database_name "test_structure"

create_database :overwrite_existing

begin

  import_database_structure
  update_comments

ensure

end
