class mcollective::config inherits mcollective
{

   File {
    ensure          => $mcollective::file_ensure,
    group           => $mcollective::file_group,
    mode            => $mcollective::file_mode,
    owner           => $mcollective::file_owner,
    backup          => $mcollective::file_backup,
    #notify          => Service['mcollective'],
    #require         => Package['mcollective']
  }



  		######### CONFIG CLIENT MCO ########
		if $mcollective::install_client == true {
	        file {
		        '/etc/mcollective/client.cfg' :
		        content     => template("mcollective/client.cfg.erb"),
		        mode       =>  "640",
	        }  
		}



  		######### CONFIG SERVER MCO ########
  		##############################################################################################################
		##  La configuration du serveur mcollective, qui sera installé sur chaque hôte que vous souhaitez contrôler.  
		##############################################################################################################
		if $mcollective::install_server == true {

			# creation directory:
			$libexec_dirs = ["/usr/libexec/mcollective/", "/usr/libexec/mcollective/mcollective/"]
			file { $libexec_dirs:
				ensure => "directory",
				mode   => 750,
			}	

		    file {
		        '/etc/mcollective/server.cfg' :
		        content   => template("mcollective/server.cfg.erb"),
		        mode      =>  "640";

		            #C’est une bonne idée de remplir le fichier de "facts.yaml" avec quelques facts à utiliser.
		            #D'abord, éditez le fichier /etc/mcollective/server.cfg pour qu’il contienne les éléments suivants
		            #Facts:
		            #factsource = Yaml 
		            #plugin.yaml = /etc/mcollective/facts.yaml
		            #(La cible pour le paramétré plugin.yaml du fichier server.conf, peut inclure plusieurs noms de  fichiers séparés par deux points):
		            '/etc/mcollective/facts.yaml' :
		            content   => template("mcollective/facts.yaml.erb"),
		            replace   => "no",
		            mode      => "640";


				                "/usr/libexec/mcollective/mcollective/agent" :
				                ensure => directory,
				                source => ["puppet:///modules/mcollective/agent"],
				                recurse => true,
				                ignore => '.git',
				                backup => false;

				                "/usr/libexec/mcollective/mcollective/application" :
				                ensure => directory,
				                source => ["puppet:///modules/mcollective/application"],
				                recurse => true,
				                ignore => '.git',
				                backup => false;

				                 #  ATTENTION !!!!!!!!!!!!!!! Ne pas utiliser "mcollective-facter-facts":  ensure uninstall
				                "/usr/libexec/mcollective/mcollective/facts" :
				                ensure => directory,
				                source => ["puppet:///modules/mcollective/facts"],
				                recurse => true,
				                ignore => '.git',
				                backup => false,
		        }

		            # Requiere:  yum install facter
		            cron { 'MCOllective':
		                    ensure      => 'present',
		                    command     => 'facter -y > /etc/mcollective/facts.yaml',
		                    minute      => '30',
		                    hour        => '*',
		                    monthday    => '*',
		                    month       => '*',
		                    weekday     => '*',
		                    provider    => 'crontab',
		                    user        => 'root',
		            }
		}

}