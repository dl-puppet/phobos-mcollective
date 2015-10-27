# définition des paramètres par défaut 

class mcollective::params
{
    ######## configuration install ########
    $install_server 		= true
    $install_client 		= true

	######### PACKAGES ######## 
	$package_manage       	= true
	$package_ensure       	= 'present' 
	$package_common         = ['rubygem-stomp','ruby-shadow', 'rubygem-net-ping'] #rubygem-sysproctable
  	$package_client         = 'mcollective-client'
  	$package_server         = 'mcollective'  #mcollective-common
    #yum install http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm	  
		  
	######### SERVICES ########
	$service_manage 		= true
	$service_client   		= 'mcollective'
	$service_server			= 'mcollectived'
	$service_ensure         = 'running'            
	$service_enable         = true
	$service_hasstatus		= true
	$service_hasrestart 	= true


	###### CONFIG_FILES ######      
	$file_ensure            = 'file'  
	$file_group             = '0' 
	$file_mode              = '0644' 
	$file_owner             = '0'  
	$file_backup            = '.puppet-bak'   
}
