#
# Application specific settings. Define override values in AeriusSettings.User.rb (same location).
#

$repo_root_folder = File.dirname(__FILE__) + '/../../../../../../';


$runscripts_path = File.expand_path(File.dirname(__FILE__) + '/../scripts/').fix_pathname


$pg_username = 'aerius'
$pg_password = '' # Override in AeriusSettings.User.rb


$dbdata_dir = 'dbdata/aeriusII/'
$dbdata_path = File.expand_path($repo_root_folder + '/../../' + $dbdata_dir).fix_pathname


$database_name_prefix = 'COMMON'
$db_function_prefix = 'ae'


$source = :https
$target = :local

$https_data_path = 'https://nexus.aerius.nl/repository'
$https_data_username = '' # Override in AeriusSettings.User.rb
$https_data_password = '' # Override in AeriusSettings.User.rb


$git_bin_path = '' # Git bin folder should be in PATH
