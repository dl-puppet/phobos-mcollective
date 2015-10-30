# définition des paramètres par défaut 

class mcollective::params
{
    ######## configuration install ########
    $install_server 		= false
    $install_client 		= true

	######### PACKAGES ######## 
	$package_manage       	= true
	$package_ensure       	= 'present' 
	$package_common         = ['rubygem-stomp','ruby-shadow', 'rubygem-net-ping', 'facter'] #rubygem-sysproctable; stomp (debian)
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
	$file_mode              = '0640' 
	$file_owner             = 'mcollective'  
	$file_backup            = '.puppet-bak'  


	# CONFIGURATION MIDDLEWARE 
	$middlle_libdir                 = "/usr/libexec/mcollective"
	$middlle_connector              = "rabbitmq" #activemq
	$middlle_vhost                  = "/mcollective"
	$middlle_port                   = "61613"
	$middlle_user                   = "mcollective"
	$middlle_pwdclient              = "3O9oV8C9VuYhs/zCpOsvOXZwGRtdDzVQyPYawpNeBEg="
	$middlle_pwdserveur             = "li4/JW+z3LGHMN3B8h0cw60XAwjL5NhcLYSqnYEyXTY="
	$middlle_Keypsk                 = "w3QqoR20w6eDMw73q3wD/ngqPLxo/sR9NPNE3MCDXOA="
	$middlle_securityprovider       = "psk"

}
