class mcollective 
(  
 
  ######## configuration install ########
  $install_server               = $mcollective::params::install_server,
  $install_client               = $mcollective::params::install_client,

  ######### PACKAGES ########
  $package_manage               = $mcollective::params::package_manage,
  $package_ensure               = $mcollective::params::package_ensure,
  $package_common               = $mcollective::params::package_common,
  $package_client               = $mcollective::params::package_client,
  $package_server               = $mcollective::params::package_server,    
    
 
  ######### SERVICES ########
  $service_manage               = $mcollective::params::service_manage,
  $service_client               = $mcollective::params::service_client,
  $service_server               = $mcollective::params::service_server,
  $service_ensure               = $mcollective::params::service_ensure,            
  $service_enable               = $mcollective::params::service_enable,   
  $service_hasstatus            = $mcollective::params::service_hasstatus,
  $service_hasrestart           = $mcollective::params::service_hasrestart,


  ###### CONFIG_FILES ###### 
  $file_name                    = $mcollective::params::file_name,    
  $file_path                    = $mcollective::params::file_path,     
  $file_ensure                  = $mcollective::params::file_ensure,      
  $file_backup                  = $mcollective::params::file_backup,      
  $file_content                 = $mcollective::params::file_content,          
  $file_group                   = $mcollective::params::file_group,        
  $file_mode                    = $mcollective::params::file_mode,        
  $file_owner                   = $mcollective::params::file_owner,       



# -----------------------------------
# CONFIGURATION MIDDLEWARE 
# -----------------------------------
$middlle_connector              = "rabbitmq" , #activemq
$middlle_vhost                  = "/mcollective",
$middlle_port                   = "61613",
$middlle_user                   = "mcollective",
$middlle_password               = "marionette",



) inherits mcollective::params  

{
  validate_string         ($package_ensure)
  validate_bool           ($package_manage)
  validate_array          ($package_common)

  validate_bool           ($service_manage)
  validate_string         ($service_name)
  validate_string         ($service_ensure)
  validate_bool           ($service_enable)
  validate_bool           ($service_hasstatus)
  validate_bool           ($service_hasrestart)

  validate_string         ($file_name) 
  validate_string         ($file_path)    
  validate_string         ($file_ensure)      
  validate_string         ($file_backup)     
  validate_string         ($file_content)          



  anchor { 'mcollective::begin': } ->
    class { '::mcollective::install': } ->
    class { '::mcollective::config': } ->
    class { '::mcollective::service': } ->
    class { '::mcollective::user': } ->
  anchor { 'mcollective::end': }
 		  
}

