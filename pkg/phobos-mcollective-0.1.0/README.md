# phobos-mcollective

Avant de commencer, assurez d'avoir installer les dépôts Puppetlabs:

https://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html




## Configuring du broker pour MCOLLECTIVE:

La premiere étape consiste à installer un middleware (RabbitMQ ou encore ActiveMQ) qui sera utilisé pour la communication entre le client MCOllective et les serveurs gérés. Vous pouvez l'installer sur un serveur standelone ou sur un serveur Puppet existant, sauf si vous avez des centaines de nœuds à gérer.

L'installation de base des broker RabbitMQ et ActiveMQ sont hors du champ de ce document. Vous pouvez consulter mon module d'installation RabbitMQ:

https://github.com/dl-puppet/phobos-rabbitmq


Après avoir installer votre broker, vous devez lui configurer les trois éléments suivants:
-exchanges
-topics
-queues 

A partir de notre broker, nous commencon par créer un hôte virtuel, deux utilisateurs (un pour agir en tant qu'administrateur qui créera les échanges que nous aurons besoin plus tard) et certaines autorisations sur le serveur virtuel:

<blockquote>
rabbitmqadmin declare vhost name=/mcollective
rabbitmqadmin declare user name=mcollective password=xxxxxxxx tags=user
rabbitmqadmin declare user name=admin password=xxxxxxxx tags=administrator
rabbitmqadmin declare permission vhost=/mcollective user=mcollective configure='.*' write='.*' read='.*'
rabbitmqadmin declare permission vhost=/mcollective user=admin configure='.*' write='.*' read='.*'
</blockquote>


Et puis, nous devons créer "les échanges" qui sont nécessaires pour chaque collective:

<blockquote>
for collective in mcollective ; do
  rabbitmqadmin declare exchange --user=admin --password=xxxxxxx --vhost=/mcollective name=${collective}_broadcast type=topic
  rabbitmqadmin declare exchange --user=admin --password=xxxxxxx --vhost=/mcollective name=${collective}_directed type=direct
done
</blockquote>




## Génération des Keys 

La seconde étape consiste à generer trois mot de passe : 

<blockquote>
openssl rand -base64 32
</blockquote>

1er password: C'est le mot de passe client utilisé pour la connection au middleware avec les permissions d'utiliser des commandes sur le servers hosts. Il est configuré dans le fichier /etc/activemq/activemq.xml et utilisé pour l'option 'plugin.XXXXXX.pool.1.password' dans /etc/mcollective/client.cfg. Vous pouvez le renseigner dans hiera par :
<blockquote>
mcollective::middlle_pwdclient:        "pwdclient"
</blockquote>

2eme password: mot de passe utilisé par les serveurs pour ce connecter au broker avec des autorisations d'abonnement aux chaines de commandement. Il est configuré dans le fichier de /etc/activemq/activemq.xml et utilisé pour plugin.XXXXXX.pool.1.password dans /etc/mcollective/server.cfg. Vous pouvez le renseigner dans hiera par :
<blockquote>
mcollective::middlle_pwdserveur:       "pwdserveur"
</blockquote>

3eme passsword: la key pré-partagé utilisé comme un sel dans le hachage cryptographique qui est utilisé pour valider les communications entre les serveurs et le client MCOllective. Il est configuré avec la variable "plugin.psk" à la fois dans /etc/mcollective/server.cfg et /etc/mcofllective/client.cfg. Vous pouvez le renseigner dans hiera par :
<blockquote>
mcollective::middlle_Keypsk:           "Keypsk"
</blockquote>




## Configurer MCollective:

/etc/mcollective/client.cfg : C'est le fichier de configuration du client, qui doit être installé uniquement sur l'hôtes à partir duquel vous pourrez controler votre parc. 

/etc/mcollective/server.cfg: C'est le fichier de configuration du serveur mcollective, qui doit être installé sur chaque hôte que vous souhaitez contrôler. 


## Les Connector

Le logiciel MCOllective server installé sur chaque nœuds de votre parc, sont contrôlez avec un démon appelé "mcollectived". Pour que ce démon fonctionne correctement, il nécessite deux plugins. Pour atteindre les serveurs, le client utilise aussi deux plugins:

-connector = {activemq/rabbitmq} : Un plugin "connector" pour établir un lien avec le middleware et publier des sujets ou s'enregistre au topics. 
-securityprovider = {psk, SSL ou AES_SECURITY} : Un plugin de sécurité à signer (éventuellement chiffrer) qui encrypte et decryte les communications.

Ces deux connecteurs doivent être les mêmes dans votre environnement cliet/server MCOllective..


Mcollective utilise toujours le protocole STOMP lors de la connexion avec le broker, mais cela ne figure pas dans ca configuration. Dans la configuration du broker, vous ne mentionnez pas mcollective mais dites au Connector de fournir le protocole de transport STOMP. Lorsque vous faites une recherche sur Internet, vous pouvez trouver des références à un connecteur STOMP pour MCOllective. Mais, ce connecteur a été déconseillée en mcollective 2.2.3 et retiré. Il faut toujours utiliser les connector natifs ActiveMQ ou RabbitMQ. Vous pouvez le renseigner dans hiera par :

<blockquote>
mcollective::middlle_connector:       "rabbitmq"
</blockquote>

<blockquote>
mcollective::middlle_securityprovider: "psk"
</blockquote>


Vous devriez voir le serveur lié au serveur broker sur le port répertorié dans les deux fichiers server.cfg (et activemq.xml). Vous pouvez modifier le port via hiera:

<blockquote>
mcollective::middlle_port:            "61613"
</blockquote>


Testez la connectivité en allant sur le serveur middleware et confirmez que vous voyez les connexions au port 61613 de chacun des serveurs via l'utilisation des commandes : "netstat -an | grep 61613"   ou  "netstat -an -A inet6 | grep 61613"

<blockquote>
netstat -an | grep 61613
tcp        0      0 ::1:61613                   :::*                        LISTEN      
tcp        0      0 ::1:51751                   ::1:61613                   ESTABLISHED 
tcp        0      0 ::1:61613                   ::1:51751                   ESTABLISHED 
</blockquote>


Si vous ne voyez pas les connexions de ce genre, alors il y a peu être un pare-feu qui empêche les serveurs d'accès au server middleware.




## Utilisation de  MCollective

Après avoir mis en place le middleware, au moins un serveur et le  client MCOllective, vous pouvez effectuer un test pour confirmer que vos paramètres de configuration sont corrects. Notez que l'hôte MCOllective posséde a la fois un serveur MCOllective et le client d'installé. Il recevra les demandes par l'intermédiaire du middleware le même que tous les autres serveurs. 

La façon la plus courante d'interagir avec mcollective est le client de ligne de commande MCO (CLI mco), qui peut être utilisé de manière interactive ou dans des scripts. Le fichier de configuration globale pour un client mcollective est /etc/mcollective/client.cfg. 

Lors de l'utilisation de clés SSL pour l'authentification, Il sera nécessaire de créer des fichiers spécifiques à l'utilisateur.

Ainsi, les utilisateurs peuvent créer leurs propres fichiers de configuration. Le nom de fichier par défaut est ".mcollective" dans le répertoire personnel de l'utilisateur. Des fichiers de configuration alternatifs peuvent être spécifiés avec "-c configfile" sur la ligne de commande. Si vous spécifiez un fichier de configuration, le fichier de configuration global est ignoré. -c 




### Le Ping

Le test de ping est une requête de bas niveau qui confirme que le nœud du serveur communique via le middleware.
vous obtenez ainisi une liste de chaque serveur connecté à votre middleware et son temps de réponse :

<blockquote>
mco ping
pc-phobos.localdomain                    time=21.50 ms
---- ping statistics ----
1 replies max: 21.50 min: 21.50 avg: 21.50 
</blockquote>




### Les Facts 

La façon la plus complète pour identifier les groupes de systèmes est d'utiliser l'outil "facter" qui est installé par défaut avec ce module. Il contient des paires de "clé/valeur" avec des informations sur votre system local.

<blockquote>
architecture => x86_64
bios_vendor => Insyde
bios_version => F.06
</blockquote>

Le fichier /etc/mcollective/server.cfg et configuré pour contenir les éléments ci-dessous. Le paramètre plugin.yaml peut inclure plusieurs noms de fichiers séparés par deux points):

<blockquote>
factsource = Yaml 
plugin.yaml = /etc/mcollective/facts.yaml
</blockquote>


La façon la plus flexible pour obtenir des facts pour mcollective est de laisser Puppet (ou Chef) renseigner le fichier /etc/mcollective/facts.yaml. Pour ce faire le module, ajoute une entrée crontab afin de stocker les facts dans ce fichier.

<blockquote>
MCOllective
	*/30 * * * * facter -y > /etc/mcollective/facts.yaml
</blockquote>


Grace à cette configuration, vous pouvez utiliser la demande d'inventaire MCOllective afin de visualiser l'inventaire de vos server MCOllective. Cette commande permet de voir comment un serveur donné est configuré et diverses statistiques fonctionnement. Il sera également vous dire les classes Puppet qu'il utilise (si Puppet est utilisé sur l'hôte) et les facts connus sur l'hôte. 

<blockquote>
mco inventory pc-phobos.localdomain
mco inventory pc-phobos.localdomain | awk '/Facts:/','/^$/'  (Afficher que les Facts)
</blockquote>


Vous pouvez également utiliser "mco facts" pour savoir combien de serveur partagent la même valeur de facts (OS, release, etc...).
</blockquote>
mco facts operatingsystem

Report for fact: operatingsystem
    CentOS                                   found 1 times
Finished processing 1 / 1 hosts in 15.45 ms
</blockquote>

Ou encore :

</blockquote>
mco facts uptime_days

Report for fact: uptime_days
        0                                        found 1 times
Finished processing 1 / 1 hosts in 21.64 ms
</blockquote>



ATTENTION ! Nous vous conseillons de ne pas utiliser le package "mcollective-facter-facts". Cet agent peut être lent à exécuter, car il invoque l'outil 'facter' pour chaque évaluation. Il faut utiliser le facter par defaut de Puppet avec une crontab pour renseigner le fichier yaml. Vous pouvez consulter mon module d'installation Puppet:

https://github.com/dl-puppet/phobos-puppet.git




### DISCOVERY

La plupart des opérations de base effectuées par le client mcollective est de découvrir quels serveurs sont disponibles dans le MCOollectif. Il utilisera cette informations au moment de décider d'émettre des commandes. 

Par defaut, MCOllective utilise le plugin 'mc-discovery' pour déterminer à qui, il doit acheminer la commande.

<blockquote>
mco plugin doc mc
</blockquote>


Ce plugin de découverte envoie une requête de diffusion à tous les serveurs avec le filtre que vous spécifiez. Si plus de 10 serveurs répondent, alors il enverra la demande comme une émission. Si moins de 10 serveurs répondent, il va envoyer des messages directs à chaque serveur.

le paramètre "direct_addressing_threshold" dans le fichier de configuration du client permet de mofifier ce comportement!

Une façon d'éviter la découverte de diffusion utilisé par mc est d'utiliser un plugin de découverte différente. Les autres plugins de découverte fournis par défaut sont les "Flatfile" et "stdin". Ce sont des mécanismes de découverte plus limitées qui utilisent une liste de noms à partir d'un fichier ou l'entrée standard.
--nodes filname
--disc-method flatfile --discovery-option filename
--disc-method sdin

Avec l'une de ces invocations, aucune requête de diffusion sera utilisé. La demande sera envoyée directement à une file d'attente spécifique à chaque noeud: 

<blockquote>
FLATFILE / help: mco plugin doc flatfile (utilisé seulement avec --with-identity)
mco --disc-methode flatfile --discovery-option filename

STDIN / help: mco plugin doc sdin (seulement avec --with-identity)
mco --disk-methode sdin

NODES:
 --nodes serveurlist.txt
</blockquote>


Il ya un certain nombre d'autres plugins de découverte disponibles pour mcollective, y compris ceux pour PuppetDB, Chef, MongoDB, RiakDB et Elastic search...



### LES FILTRES


#### FILTRES : --with-identity/class/fact/agent

Les filtres (--with-xxx) sont utilisés par le plugin de Discovery pour limiter les envois à quelques serveurs. Les filtres peuvent être appliqués à n'importe quelle commande mcollective. Chacun produit une liste de serveurs mcollective qui correspondent aux critères demandé et ainsi limite le nombre de sortie.

Trouver tous les serveurs avec un i dans leur nom (identity):
<blockquote>mco find --with-identity /i/</blockquote>

Trouver tous les serveurs appelée 'test' suivi d'un numéro 'd':
<blockquote>mco find --with-identity /test\d/</blockquote>

Trouver tous les serveurs qui ont applique la classe Puppet 'pupclass':
<blockquote>mco find --with-class pupclass</blockquote>

Trouver tous les serveurs qui exécutent le système d'exploitation CentOS:
<blockquote>mco find --with-fact operatingsystem=CentOS</blockquote>

Trouver tous les serveurs qui ont l'agent MCOllective 'package' d'installé:
<blockquote>mco find --with-agent package</blockquote> 




#### Filtre de combinaison :  --with "classe-puppet   Facter"

Le filtre de combinaison regroupe "les classes Puppet et les facts de facter". L'exemple suivant effectue un ping seulement sur les serveurs CentOS qui applique la classe Puppet 'pupclass':

<blockquote>mco ping --with "/pupclass/ operatingsystem=CentOS"</blockquote>




#### filtre de sélection :  --select  "  AND/OR/NOT OR  "

C'est le filtre le plus puissant disponible dans MCOllective. C'est le seul filtre où vous pouvez utiliser les opérandes AND, OR et NOT OR. Cela peut par exemple, vous permettre de filtrer des serverus de type virtualisés et qui utilsent des classe Puppet 'pupclass1' soit une classe Puppet "pupclass2":  

<blockquote>mco ping --select " ( /pupclass1/ or /pupclass2/ ) and is_virtual=true"</blockquote>

ou encore: 

<blockquote>mco ping --select  "operatingsystem=CentOS and /pupclass/"</blockquote>

Ping chaque server de type CentOS qui ne sont pas dans l'environnement de développement:
<blockquote>mco ping --select  "operatingsystem=CentOS and !environment=dev"</blockquote>




#### Limiter les réponces :  --limit / --one / --batch --batch-sleep

Au-delà de ce que peuvent faire les filtres, vous pouvez également limiter le nombre d'envoi ou le nombre de processus simultané.

<blockquote>mco find --limit 15</blockquote>


Limité l'action MCOllective à un seul serveur (utilisé dans un but de test):
<blockquote>mco facts architecture --one --with-fact operatingsystem=CentOS</blockquote>

Limité l'action MCOllective à cinq serveurs qui ont la classe Puppet pupclass appliquée:
<blockquote>mco facts osfamilly --limit 5 --with-class pupclass</blockquote>

Limité l'action MCOllective sur un tiers des serveurs virtuel qui ont la classe Puppet pupclass appliquée:
<blockquote>mco facts is_virtual --limit 33% --with-class webserver</blockquote>

Requête pour avoir le status du package sudo pour des lots de 10 serveurs executé toutes les 20 secondes :
<blockquote>mco package status sudo --batch 10 --batch-sleep 20</blockquote>

Interroger la version Puppet de tous les serveurs allemands, avec interrogation de cinq serveurs toutes les 30 secondes:
<blockquote>mco package status puppet --batch 5 --batch-sleep 30 --with-fact country=de</blockquote>




### LES SORTIES : -no-progress / --verbose / --no-results / --display

Avec MCOllective, vous pouvez également contrôler les sortie que vous recevez en réponse. Cela permet d'afficher les réponces de maniére structurées au lieu de la réponce convivial en mode texte:

<blockquote>-no-progress</blockquote>:   Cette option permet d'afficher le résultat sans la bar de status

L'option '--verbose' vous indique combien de temps prend la découverte, et vous donne des statistiques complètes:
<blockquote>mco plugin --verbose command option ....</blockquote>

L'option '--no-results' envoie les commandes mais ignore la file d'attente de réponse:
<blockquote>mco plugin --no-results command option.....</blockquote>

L'option '--display' affiche les réponses échoué ou seulement réussi dans une requete:
<blockquote>mco plugin --display failed command options...</blockquote>
<blockquote>mco plugin --display ok command options...</blockquote>
<blockquote>mco plugin --display all command options...</blockquote>




### PUPPET:
L'agent puppet écrit les sortie "classes" dans le fichier catalogue puppet 'classes.txt' dans le $statedir (/var/lib/puppet/classes.txt). Mcollective sait où ce est par défaut.

il faut que l'option 'classfile' présent dans la section [agent] du fichier puppet.conf corresponde au 'classesfile' du fichier de configuration server.cfg de mcollective.  

Ainsi Mcollective est capable de savoir à quel classe l'agent est associé.






### WEB CLIENT:
Il existe deux interfaces Web disponibles pour la gestion mcollective. Puppet Labs fournit une interface Web pour contrôler mcollective dans leur ligne de produits de marionnettes Enterprise.

	-mcomaster: interface free disponible sur: https://github.com/ajf8/mcomaster



### AGENT ET PLUGINS CLIENT:
Puppet Labs fournit un certain nombre d'agents mcollective qui savent comment faire les tâches de gestion de systèmes commune (par exemple, une requête, démarrer et arrêter des processus, et de requête, installer et supprimer des paquetages).
	-mcollective-filemgr-agent
	-mcollective--nettest-agent
	-mcollective--package-agent
	-mcollective--service-agent

Vous aurez besoin de le faire sur chaque serveur dans votre environnement. Sur les postes clients, vous aurez besoin d'installer le module client correspondant.

Le fichiers du plugin agent sont nommés libdir/mcollective/agent/name(rb|ddl|erb).. Il ya habituellement une application cliente dans libdir/mcollective/agent/NAME.rb. Il peut y avoir util ou d'autres répertoires, qui doivent être copiés mot à mot.

!!!!!!!!!!!!!!Le répertoire mcollective va à l'intérieur libdir. Dans le cas de Red Hat, cela signifie que le chemin d'accès complet contient la chaîne mcollective/mcollective; veillez à ne pas sauter accidentellement le deuxième mcollective

Après avoir installé de nouveaux agents sur un nœud de serveur, vous dire mcollectived pour recharger les agents. La méthode la plus simple est de redémarrer mcollectived. mco inventory nous indique si les nouveaux agent son disponible.
mco inventory nodename | awk ' /Agents:/','/^$'

Vous pouvez également interroger pour obtenir une liste de chaque serveur qui possède l'agent installé:
mco find --with-agent filemgr

Pour interagir avec ces agents, nous avons besoin d'avoir installé les plugins de clients


Desactiver un agent sans le desinstallé: 
Il ya deux façons de désactiver un agent. La première option est dans le fichier de configuration du serveur.

plugin.plugin_name.activate_agent = false

L'autre façon est de créer un fichier de configuration pour cet agent particulier:

$ echo "activate_agent = false" | tee -a /etc/mcollective/plugins.d/plugin_name.cfg

ous pouvez obtenir la list des applications disponible sur un node avec la commande 'doc':

mco plugin doc
ou
mco plugin doc agent/package

Les applications ajoutent sous-commandes personnalisées (appelées faces) au client de mco, permettant un accès facile aux commandes fournies par chaque plugin client. 

La commande 'mco plugin package xxx' permet de créer des plugins.


yum search --enablerepo=puppetlabs* mcollective 



### SERVER STATISTIQUE:
En plus de la liste des agents disponibles sur un serveur, mcollective rapporte aussi de retour un bon nombre de statistiques de la demande d'inventaire



### MONITORING SERVERS:
Un contrôle actif serait de lancer un appel à un agent disponible sur chaque nœud et valider les résultats. Cela pourrait être quelque chose d'aussi simple que mco ping, qui est un test de connectivité de bas niveau qui ne nécessite pas d'authentification ou d'autorisation. Ou vous pourriez tester à un plugin spécifique (par exemple, un test de NRPE). Un exemple de la façon de vérifier cela avec Nagios peut être trouvé à Puppet Labs wiki AgentRegistrationMonitor.



vérifier quels systèmes ont l'agent mcollective marionnettes installé:
mco find --with-agent puppet
mco puppet count
mco puppet summary


## CONTROLLER LE DAEMON PUPPET:
Lors de la maintenance, vous pouvez désactiver l'agent de marionnettes sur certains noeuds. Lorsque vous désactivez l'agent, vous pouvez fournir un message de laisser les autres savent ce que vous faites:
mco puppet disable --with-identity test.node.local message="Arret du service puppet pour test"
mco puppet runonce --with-identity test.node.local

Pour réactiver l'agent:
mco puppet enable --with-identity test.node.local



INVOQUER PUPPET RUN:
voir l'aide : # mco help puppet

L'invocation simple est naturellement à fonctionner immédiatement marionnettes sur un système:
mco puppet runonce --with-identoty test.node.local

mco puppet status --with-identity test.node.local

Que faire si vous avez besoin pour exécuter marionnettes instantanément sur chaque hôte CentOS pour fixer les fichier sudoers?
mco puppet runonce --tags=sudo --with-fact operatingsystem=CentOS
mco puppet status --wf operatingsystem=CentOS










