# phobos-mcollective

############################################
Génération des Keys:
############################################
La première étape consiste à generer trois mot de passe :	
# openssl rand -base64 32
	
1er: client password pour connection au middleware ave les permissions d'utiliser des commandes sur le servers hosts. Devrait être attribué au client de l'utilisateur dans le fichier de /etc/activemq/activemq.xml et utilisé pour plugin.activemq.pool.1.password dans /etc/mcollective/client.cfg

2eme: mot de passe server utilise par les serveurs pour ce connecter au broker avec des autorisations d'abonnement aux chaines de commandement.Devrait être attribué au serveur de l'utilisateur dans le fichier de /etc/activemq/activemq.xml et utilisé pour plugin.activemq.pool.1.password dans /etc/mcollective/server.cfg


3eme: la key Pre-partagé utilisé comme un sel dans le hachage cryptographique utilisé pour valider les communications entre le serveur et le client, se assurer que personne ne peut modifier la demande de charge utile en transit.Devrait être utilisé comme valeur pour plugin.psk à la fois /etc/mcollective/server.cfg et /etc/mcofllective/client.cfg


installer les dépôts sur Enterprise Linux 6:
yum install http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm



############################################
Configuring du middleware pour MCOLLECTIVE:
############################################
La première étape est d'installer un middleware (RabbitMQ ou encore ActiveMQ) qui sera utilisé pour la communication entre clients et serveurs. Vous pouvez l'installer sur un serveur existant Puppet. Sauf si vous avez des centaines de nœuds.

Basic installation of the RabbitMQ broker is out of scope for this document apart from the basic broker you need to enable the Stomp plugin and the CLI Management Tool.(voir ci dessus)

With that in place you need to create a few:
-exchanges
-topics
-queues 

First we create a virtual host, two users (one to act as an administrator who will create the exchanges we need later) and some permissions on the vhost:

rabbitmqadmin declare vhost name=/mcollective
rabbitmqadmin declare user name=mcollective password=marionette tags=
rabbitmqadmin declare user name=admin password=bench tags=administrator
rabbitmqadmin declare permission vhost=/mcollective user=mcollective configure='.*' write='.*' read='.*'
rabbitmqadmin declare permission vhost=/mcollective user=admin configure='.*' write='.*' read='.*'




Et puis, nous devons créer "les échanges" qui sont nécessaires pour chaque collective:

for collective in mcollective ; do
  rabbitmqadmin declare exchange --user=admin --password=bench --vhost=/mcollective name=${collective}_broadcast type=topic
  rabbitmqadmin declare exchange --user=admin --password=bench --vhost=/mcollective name=${collective}_directed type=direct
done



############################################################################
Install MCollective:
############################################################################
installer les dépôts sur Enterprise Linux 6:
yum install http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm


#yum install mcollective
#chkconfig mcollective on


le fichier /etc/mcollective/server.cfg:
Le texte suivant est le fichier de configuration du serveur mcollective, qui doit être installé sur chaque hôte que vous souhaitez contrôler. Notez que vous devez remplacer deux des mots de passe dans ce fichier et aussi le répertoire de libdir.


XXXXXXXXXXXXXXXXx






*Mcollective utilise toujours le protocole STOMP lors de la connexion avec les broker, mais cela ne figure pas dans ca configuration.Dans la configuration du broker, vous ne mentionnez pas mcollective mais dites au transportConnector de fournir STOMP transport protocole.Lorsque vous faites une recherche sur Internet, vous pouvez trouver des références à un connecteur STOMP. Ce connecteur a été déconseillée en mcollective 2.2.3 et retiré.Toujours utiliser les ActiveMQ et RabbitMQ connecteurs natifs



le fichier /etc/mcollective/client.cfg.
le fichier de configuration du client, qui doit être installé uniquement sur l'hôtes à partir duquel vous pourrez contrloer votre parc. Avec le modèle pré-partagée clé de sécurité, n'importe qui peut lire le fichier client.cfg peut trouver le mot de passe utilisé pour publier des demandes. Je vous recommande de limiter les personnes qui peuvent lire le fichier client 

#yum install mcollective-client
#chmod 640 /etc/mcollective/client.cfg
#chown root:wheel /etc/mcollective/client.cfg


demarrer le service:
# service mcollective start



Test de l'installation:
A ce moment, vous devriez voir le serveur lié au serveur broker sur le port répertorié dans les deux fichiers server.cfg (et activemq.xml):
Testez la connectivité de serveur en allant sur le système de middleware et confirmez que vous voyez les connexions au port 61613 de chacun des serveurs:
#netstat -an | grep 61613
#netstat -an -A inet6 | grep 61613

[root@pc-phobos opt]# netstat -an | grep 61613
tcp        0      0 ::1:61613                   :::*                        LISTEN      
tcp        0      0 ::1:51751                   ::1:61613                   ESTABLISHED 
tcp        0      0 ::1:61613                   ::1:51751                   ESTABLISHED 

Si vous ne voyez pas les connexions de ce genre, alors il ya un pare-feu qui empêche les serveurs d'accès au courtier de middleware.


Après avoir mis en place un hôte de middleware, au moins un serveur et un client, vous pouvez effectuer un test pour confirmer que vos paramètres de configuration sont corrects. 


Notez que l'hôte a la fois le serveur et le logiciel client installé. Il recevra les demandes par l'intermédiaire du middleware le même que tous les autres serveurs. Le test de ping est une requête de bas niveau qui confirme que le nœud du serveur communique via le middleware:
vous obtenez une liste de chaque serveur connecté à votre middleware et son temps de réponse,

# mco ping
pc-phobos.localdomain                    time=21.50 ms

---- ping statistics ----
1 replies max: 21.50 min: 21.50 avg: 21.50 




Line de commande client:
La façon la plus courante d'interagir avec mcollective est le client de ligne de commande MCO, qui peut être utilisé de manière interactive ou dans des scripts. Il est aussi relativement facile à écrire d'autres clients dans Ruby, qui peuvent être utilisés comme backends pour les applications de l'interface graphique ou de la colle dans une infrastructure réactive.Le fichier de configuration globale pour un client mcollective sera stocké dans le répertoire d'installation, /etc/mcollective/client.cfg 

Les utilisateurs peuvent créer leurs propres fichiers de configuration. Le nom de fichier par défaut est .mcollective dans le répertoire personnel de l'utilisateur. Fichiers de configuration alternatifs peuvent être spécifiés avec "-c configfile" sur la ligne de commande. Chaque fichier de configuration doit être entière et complète. Il est nécessaire de créer des fichiers spécifiques à l'utilisateur lors de l'utilisation de clés SSL pour l'authentification

Si vous spécifiez un fichier de configuration, le fichier de configuration global est ignoré. -c 


#connector : 
Le logiciel installé sur les nœuds sont contrôlez avec un démon appelé mcollectived.Chaque agent a un client de correspondance ou une application qui sait comment émettre des demandes spécifiques à cet agent.
Sur chaque nœud nous avons installé le service mcollectived. Pour ce démon de fonctionner correctement, il nécessite deux plugins:

	-connector plugin: etablie un lien avec le middleware et s'enregistre au topics.
	-security plugin: encrypte et decryte les communications

Pour atteindre les serveurs, le client utilise deux plugins:
-connector = {activemq/rabbitmq} : Un plugin "connector" pour établir un lien avec le middleware et publier aux sujets.
-securityprovider = psk : Un plugin de sécurité à signer (éventuellement chiffrer) la charge utile de données
Ces deux connecteurs doivent être les mêmes dans votre environnement.


#Facts:
La façon la plus complète pour identifier les groupes connexes de systèmes est par des Facts, qui sont des paires clé / valeur avec des informations sur votre serveur. La façon la plus courante pour obtenir des Facts est en utilisant le programme de facter de Puppet Labs.

# yum install facter

[root@pc-phobos mcollective]# facter 
architecture => x86_64
augeasversion => 1.0.0
bios_release_date => 06/04/2012
bios_vendor => Insyde
bios_version => F.06
...
Ce est une bonne idée de remplir le fichier de "facts.yaml" avec quelques faits à utiliser.D'abord, éditez le fichier /etc/mcollective/server.cfg pour contenir les éléments suivants(La cible pour le paramètre plugin.yaml pourrait inclure plusieurs noms de fichiers séparés par deux points):
# Facts
factsource = Yaml 
plugin.yaml = /etc/mcollective/facts.yaml


La façon la plus flexible pour obtenir des Facts pour mcollective est de laisser de Puppet ou Chef leur fournir pour vous. Pour l'instant, un moyen rapide pour stocker beaucoup de Facts utiles est d'avoir cron invoke facter et stocker les résultats:

/etc/cron.d/facts.sh
	*/30 * * * * facter -y > /etc/mcollective/facts.yaml

Alternativement, vous pouvez simplement créer ce fichier et entrez quelques faits aléatoires des fins d'apprentissage. Le fichier doit être en format YAML dictionnaire. 


Une fois que vous avez effectué les modifications, vous pouvez utiliser la demande de l'inventaire et de lire la sortie pour voir si les faits sont disponibles sur le noeud:

# mco inventory pc-phobos.localdomain
# mco inventory pc-phobos.localdomain | awk '/Facts:/','/^$/'  (Afficher ue les Facts)


Vous pouvez également interroger pour savoir comment de nombreux nœuds partagent la même valeur de facts (OS, release, etc...).

# mco facts operatingsystem
Report for fact: operatingsystem
        CentOS                                   found 1 times
Finished processing 1 / 1 hosts in 15.45 ms


Ou encore :

# mco facts uptime_days
Report for fact: uptime_days
        0                                        found 1 times
Finished processing 1 / 1 hosts in 21.64 ms


# mco facts chef_environment
# mco facts 

ATTENTION !!!!!!!!!!!!!!! Ne pas utiliser "mcollective-facter-facts":
Cet agent peut être lente à exécuter, car il invoque facter pour chaque évaluation. 
Il faut utiliser le facter par defaut de Puppet avec une crontab pour renseigner le fichier yaml.


Une des commandes de base fournies dans le client mcollective est la commande d'inventaire. Cette commande vous permet de voir comment un serveur donné est configuré, ce qui les collectifs il est partie et diverses statistiques fonctionnement.

sortie est ce que les agents et les plugins sont installés sur l'hôte. Il sera également vous dire ce que les classes de marionnettes qu'il connaît (si marionnettes est en cours d'exécution sur l'hôte) et les faits sont connus sur l'hôte (si vous configurez faits dans la section précédente). Vous devez exécuter cette commande sur un de vos serveurs et d'examiner la sortie

Vous pouvez générer des rapports en vrac de l'inventaire

mco inventory --script inventory.mc   (ex de perso developpe en ruby)






DISCOVERY
Un des la plupart des opérations de base effectuées par le client mcollective est de découvrir quels serveurs sont disponibles dans le collectif. Il utilisera cette informations au moment de décider d'émettre des commandes. 


[root@pc-phobos ~]# mco find --with-identity /a/ --verbose
Discovering hosts using the mc method for 2 second(s) .... 1
pc-phobos.localdomain
Discovered 1 nodes in 2.00 seconds using the mc discovery plugin

Comment le client n'a déterminer quels serveurs correspondait le filtre? La réponse, ce est qu'il a utilisé le plugins mc-discovery configuré dans le fichier client.cfg de demander aux serveurs.

[root@pc-phobos ~]# mco plugin doc mc
mc
==
MCollective Broadcast based discovery
      Author: R.I.Pienaar <rip@devco.net>
     Version: 0.1
     License: ASL 2.0
....
..


Le plugin de découverte de mc envoie une requête de diffusion à tous les serveurs avec le filtre que vous spécifiez. Si plus de 10 serveurs répondent, alors il enverra la demande comme une émission. Si moins de 10 serveurs répondent, il va envoyer des messages directs à chaque serveur.

le paramètre direct_addressing_threshold dans le fichier de configuration du client permet de mofifier le comportement!


Une façon d'éviter la découverte de diffusion utilisé par mc est d'utiliser un plugin de découverte différente. Les autres plugins de découverte fournis par défaut sont les "Flatfile" et "stdin". Ce sont des mécanismes de découverte plus limitées qui utilisent une liste de noms à partir d'un fichier ou l'entrée standard.
--nodes filname
--disc-method flatfile --discovery-option filename
--disc-method sdin

Avec l'une de ces invocations, aucune requête de diffusion sera utilisé. La demande sera envoyée directement à une file d'attente spécifique à chaque noeud: voir 'mco plugin doc flatfile'

# mcp rpc rpcutil ping --disc-method flatfile --disc-o| /.../list-server

mco RPC est une méthode pour envoyer une demande à l'agent sans utiliser l'application cliente.

Il ya un certain nombre d'autres plugins disponibles pour mcollective de découverte, y compris ceux pour PuppetDB, Chef cuisinier, MongoDB, RiakDB et Elastic search. 



FILTRE
Les filtres sont utilisés par le plugin de Discovery pour limiter les serveurs sont envoyés une demande. Les filtres peuvent être appliqués à ne importe quelle commande mcollective.Chacun produit une liste de serveurs mcollective qui correspondent aux critères.

exemple:

nous trouverons tous les hôtes avec un i en leur nom:
# mco find --with-identity /i/

Inscrivez tous les serveurs Web Web appelée suivi d'un numéro:
# mco find --with-identity /ŵeb\d/

Listez tous les nœuds qui ont classe Puppet 'wzbserver' qui leur est appliquée:
# mco find --with-class webserver

Afficher tous les nœuds qui exécutent le système d'exploitation CentOS:
# mco find --with-fact operatingsystem=CentOS

Afficher tous les nœuds qui ont l'agent package d'installé:
# mco find --with-agent package 

l existe deux types de filtres de combinaison. Le premier type regroupe les classes de Puppet et des facts de facter. exemple où nous ping seuls les hôtes CentOS avec une classe Puppet 'nameserver':
# mco ping --with "/nameserver/ operatingsystem=CentOS"

Le deuxième type est appelé un filtre de sélection et est le filtre le plus puissant disponible.Ce est le seul filtre où vous pouvez utiliser les opérandes AND et OR.Ce est le seul filtre où vous pouvez utiliser les opérandes NOT OR.

# mco ping --select  "operatingsystem=CentOS and /nameserver/"

Ping CentOS chaque nœud qui ne est pas dans l'environnement de développement:
# mco ping --select  "operatingsystem=CentOS and !environment=dev"


Ping chaque serveur web virtualisé:
# mco ping --select " ( /httpd/ or /nginx/ ) and is_virtual=true"

comment faire correspondre nœuds virtualisés avec soit l'httpd ou nginx classe de marionnettes comment faire correspondre nœuds virtualisés avec soit l'httpd ou nginx classe de marionnettes


Au-delà de ce que peuvent faire les filtres, vous pouvez également limiter le nombre de serveurs de recevoir la demande ou le nombre de processus en même temps.Au-delà de ce que peuvent faire les filtres, vous pouvez également limiter le nombre de serveurs de recevoir la demande ou le nombre de processus en même temps.

# mco find --limit 15

Un seul serveur CentOS:
# mco facts architecture --one --with-fact operatingsystem=CentOS

Cinq serveurs qui ont la classe serveur web de marionnettes qui leur est appliquée:
# mco facts osfamilly --limit 5 --with-class webserver

Un tiers des serveurs qui ont la classe serveur web de marionnettes qui leur est appliquée:
# mco facts is_virtual --limit 33% --with-class webserver

Requête sudo version du paquet dans des lots de 10 serveurs espacé 20 secondes en dehors:
# mco package status sudo --batch 10 --batch-sleep 20

Interroger la version marionnettes de tous les serveurs allemands, cinq traitement toutes les 30 secondes:
# mco package status puppet --batch 5 --batch-sleep 30 --with-fact country=de

Ping chaque serveur avec aw en son nom sans délai-pas de dosage:
# mco ping --with-identity /w/





OUTPUT:
vous pouvez également contrôler la sortie vous recevez en réponse. Elle fournit des données structurées au lieu de texte convivial en réponse: (# mco plugin --json command options....)

--no-progress :   sans la status bar

Cela vous indique combien de temps prend la découverte, et vous donne des statistiques RPC complètes:
# mco plugin --verbose command option ....

Cela envoie les commandes mais ignore la file d'attente de réponse tout à:
# mco plugin --no-results command option.....

pour afficher les réponses seulement échoué ou seulement réussi dans une requete:
# mco plugin --display failed command options...
# mco plugin --display ok command options...
# mco plugin --display all command options...




PUPPET:
L'agent puppet écrit les sortie "classes" dans le fichier catalogue puppet 'classes.txt' dans le $statedir (/var/lib/puppet/classes.txt). Mcollective sait où ce est par défaut.

il faut que l'option 'classfile' présent dans la section [agent] du fichier puppet.conf corresponde au 'classesfile' du fichier de configuration server.cfg de mcollective.  

Ainsi Mcollective est capable de savoir à quel classe l'agent est associé.



COMPLETION BASH:
Mcollective fournit un plugin pour bash pour permettre l'achèvement de ligne de commande.
# cd marionette-collective-2.5.3
# cp ext/bash/mco_completion.sh /etc/bash_completion.d/



WEB CLIENT:
Il existe deux interfaces Web disponibles pour la gestion mcollective. Puppet Labs fournit une interface Web pour contrôler mcollective dans leur ligne de produits de marionnettes Enterprise.

	-mcomaster: interface free disponible sur: https://github.com/ajf8/mcomaster



AGENT ET PLUGINS CLIENT:
Puppet Labs fournit un certain nombre d'agents mcollective qui savent comment faire les tâches de gestion de systèmes commune (par exemple, une requête, démarrer et arrêter des processus, et de requête, installer et supprimer des paquetages).
	-mcollective-filemgr-agent
	-mcollective--nettest-agent
	-mcollective--package-agent
	-mcollective--service-agent

Vous aurez besoin de le faire sur chaque serveur dans votre environnement. Sur les postes clients, vous aurez besoin d'installer le module client correspondant.

Le fichiers du plugin agent sont nommés libdir/mcollective/agent/name(rb|ddl|erb).. Il ya habituellement une application cliente dans libdir/mcollective/agent/NAME.rb. Il peut y avoir util ou d'autres répertoires, qui doivent être copiés mot à mot.

!!!!!!!!!!!!!!Le répertoire mcollective va à l'intérieur libdir. Dans le cas de Red Hat, cela signifie que le chemin d'accès complet contient la chaîne mcollective/mcollective; veillez à ne pas sauter accidentellement le deuxième mcollective

Après avoir installé de nouveaux agents sur un nœud de serveur, vous dire mcollectived pour recharger les agents. La méthode la plus simple est de redémarrer mcollectived. mco inventory nous indique si les nouveaux agent son disponible.
# mco inventory nodename | awk ' /Agents:/','/^$'

Vous pouvez également interroger pour obtenir une liste de chaque serveur qui possède l'agent installé:
# mco find --with-agent filemgr

Pour interagir avec ces agents, nous avons besoin d'avoir installé les plugins de clients


Desactiver un agent sans le desinstallé: 
Il ya deux façons de désactiver un agent. La première option est dans le fichier de configuration du serveur.

plugin.plugin_name.activate_agent = false

L'autre façon est de créer un fichier de configuration pour cet agent particulier:

$ echo "activate_agent = false" | tee -a /etc/mcollective/plugins.d/plugin_name.cfg

ous pouvez obtenir la list des applications disponible sur un node avec la commande 'doc':

# mco plugin doc
ou
# mco plugin doc agent/package

Les applications ajoutent sous-commandes personnalisées (appelées faces) au client de mco, permettant un accès facile aux commandes fournies par chaque plugin client. 

La commande 'mco plugin package xxx' permet de créer des plugins.


# yum search --enablerepo=puppetlabs* mcollective 



SERVER STATISTIQUE:
En plus de la liste des agents disponibles sur un serveur, mcollective rapporte aussi de retour un bon nombre de statistiques de la demande d'inventaire



MONITORING SERVERS:
Un contrôle actif serait de lancer un appel à un agent disponible sur chaque nœud et valider les résultats. Cela pourrait être quelque chose d'aussi simple que mco ping, qui est un test de connectivité de bas niveau qui ne nécessite pas d'authentification ou d'autorisation. Ou vous pourriez tester à un plugin spécifique (par exemple, un test de NRPE). Un exemple de la façon de vérifier cela avec Nagios peut être trouvé à Puppet Labs wiki AgentRegistrationMonitor.



vérifier quels systèmes ont l'agent mcollective marionnettes installé:
mco find --with-agent puppet
mco puppet count
mco puppet summary


CONTROLLER LE DAEMON PUPPET:
Lors de la maintenance, vous pouvez désactiver l'agent de marionnettes sur certains noeuds. Lorsque vous désactivez l'agent, vous pouvez fournir un message de laisser les autres savent ce que vous faites:
# mco puppet disable --with-identity test.node.local message="Arret du service puppet pour test"
# mco puppet runonce --with-identity test.node.local

Pour réactiver l'agent:
# mco puppet enable --with-identity test.node.local



INVOQUER PUPPET RUN:
voir l'aide : # mco help puppet

L'invocation simple est naturellement à fonctionner immédiatement marionnettes sur un système:
# mco puppet runonce --with-identoty test.node.local

# mco puppet status --with-identity test.node.local

Que faire si vous avez besoin pour exécuter marionnettes instantanément sur chaque hôte CentOS pour fixer les fichier sudoers?
# mco puppet runonce --tags=sudo --with-fact operatingsystem=CentOS
# mco puppet status --wf operatingsystem=CentOS










