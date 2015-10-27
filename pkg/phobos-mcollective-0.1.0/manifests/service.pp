class mcollective::service inherits mcollective
{
    if $mcollective::service_manage == true { 

        Service { 
            ensure      => $mcollective::service_ensure,
            enable      => $mcollective::service_enable,
            hasstatus   => $mcollective::service_hasstatus,
            hasrestart  => $mcollective::service_hasrestart,
        }

				 if $client == true {
		    		service { $mcollective::service_client : 
		    		#require     => Package[""],
		    		}
				}


				 if $server == true {	        
		    		service { $mcollective::service_server : 
					#require     => Package[""],
		    		}
				}
	}


}