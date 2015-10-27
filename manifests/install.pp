class mcollective::install inherits mcollective
{
	if $mcollective::package_manage == true { 

		Package {       
    		ensure               => $mcollective::package_ensure,
    		#before               => File['$mcollective::file_name']         
    	}

    		package { $mcollective::package_common : 
			#contain mcollective::mcollective
			}

				 if $mcollective::install_client == true {
		    		package { $mcollective::package_client : } 
				}


				 if $mcollective::install_server == true {	        
		    		package { $mcollective::package_server : }
				}
	}
} 