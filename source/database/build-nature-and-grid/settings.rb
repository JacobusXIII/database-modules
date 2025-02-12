#
# Product specific database build settings.
#

$product = :"build-nature-and-grid" # The product these settings are for.

#-------------------------------------

source_path = File.dirname(__FILE__) + '/../../'
database_path = '/database/' + $product.to_s + '/'
sql_path = '/src/main/sql/'
data_path = '/src/data/sql/'
config_path = '/src/build/config/'
settings_file = 'AeriusSettings.rb'

#-------------------------------------

$project_settings_file = File.expand_path(source_path + database_path + config_path + settings_file).fix_pathname

$common_sql_paths = [
	File.expand_path(source_path + '/modules/' + sql_path).fix_pathname
]

puts $common_sql_paths

$product_sql_path = File.expand_path(source_path  + database_path + sql_path).fix_pathname

$common_data_paths = [
	File.expand_path(source_path + '/modules/' + data_path).fix_pathname
]

$product_data_path = File.expand_path(source_path + database_path + data_path).fix_pathname
