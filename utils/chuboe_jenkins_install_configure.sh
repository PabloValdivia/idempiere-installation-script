## NOTE: this is not an automated isntall script (not yet)
## The below steps help you create an independent jenkins machine to build iDempiere and your plugins
## Because Jenkins runs on port 8080 by default, you will probably want to install the below on a dedicated machine

## ASSUMPTIONS
## Ubuntu 18.04
## local OS username = ubuntu
JENKINS_OS_USER="ubuntu"

#####Install needed tools
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update
sudo apt-get install openjdk-11-jdk -y

wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins zip mercurial htop s3cmd rpl ant maven

#####clone a local repository of iDempiere
#  doing so insulates you (and jenkins) from the many changes that happen in the main bitbucket repository
#  FYI - jenkins will create yet another clone for its build purposes
cd /opt/
sudo mkdir source
sudo chown -R $JENKINS_OS_USER:$JENKINS_OS_USER source
cd source
mkdir idempiere_source
cd idempiere_source
hg clone https://bitbucket.org/idempiere/idempiere

## NOTE: Jenkins will be launched as a daemon up on start. See the following for more detail:

#####Install Jenkins plugins (performed in jenkins UI)
# navigate to: www.YourURL.com:8080
# follow the instructions to create your admin account
# Jenkins Menu => Manage Jenkins => Manage Plugins => Available tab => Choose following plugins => "Install Without Restart"
## required
# (1) mercurial
# (2) maven integration
# (3) pipeline maven integration
## optional
# (3) Log Parser - scans logs for known issues - flags the build as a fail if issues found
# (4) Naginator - automatically kicks off a re-build if a fail is encountered. This is helpful if mirrors are acting flakey.

#####Configure Maven
# Jenkins Menu => Manage Jenkins => Global Tool Configuration => Maven section
# Add Maven button
# Name: Maven
# Install automatically: checked
# Version: 3.6.0

#####Create a new 'idempiere62' maven project
# Source Code Management => Mercurial with:
# URL: /opt/source/idempiere_source/idempiere
# Revsion Type: Branch
# Revision: release-6.2
#
# PreStep: Execute shell with:
# rm -rf ${WORKSPACE}/org.idempiere.p2/target/products
#
# Build with:
# Root POM: pom.xml
# Goals and options: verify -U




#####Using Apache as a reverse proxy to protect Jenkins
sudo apt-get install -y apache2
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2dissite 000-default

# The below is good for a bash script. If you are copying and pasting commands, just copy and paste the stuff inside the EOL to /etc/apache2/sites-available/jenkins.conf
JENKINS_TEMP=~/jenkins_temp.conf
JENKINS_CONF=/etc/apache2/sites-available/jenkins.conf
cat >$JENKINS_TEMP <<EOL
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName ci.company.com
        ServerAlias ci
        ProxyRequests Off
        <Proxy *>
                Order deny,allow
                Allow from all
        </Proxy>
        ProxyPreserveHost on
        ProxyPass / http://localhost:8080/ nocanon
        AllowEncodedSlashes NoDecode
</VirtualHost>
EOL
sudo mv $JENKINS_TEMP $JENKINS_CONF
sudo chown root:root $JENKINS_CONF
# end of file creation and move

sudo a2ensite jenkins
sudo service apache2 restart

#Note - I could not get ubuntu to wget files from mavensync.zkoss.org
#Instead, I had to create my own local copy. This section details the steps. Hopefully, you will not need to do this!!
# get the copy of the maven direcotry here: https://drive.google.com/file/d/0Byf55-KOXmDrOHJqbExLS0lzWFE/view?usp=sharing -O maven2.tar.gz
# untar it in /var/www/html/
# make sure the reverse proxy is off (if enabled above):
 ###  bring down the proxy
 #sudo a2dissite jenkins.conf
 #sudo a2ensite 000-default.conf
 #sudo service apache2 reload
 ###  bring up the proxy
 #sudo a2dissite 000-default.conf
 #sudo a2ensite jenkins.conf
 #sudo service apache2 reload
#update /etc/hosts to point to your local machine 127.0.0.1 mavensync.zkoss.org

#####Create web directories publishing p2 - only needed if you want to use apache instead of jenkins itself - otherwise, skip to the next step
## This section is commented out because I use apache to act as a reverse proxy
#sudo apt-get -y install apache2
#sudo mkdir /opt/idempiere-builds
#sudo mkdir /opt/idempiere-builds/idempiere.p2
#sudo mkdir /opt/idempiere-builds/idempiere.migration
#sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.p2
#sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.migration
#
#cd /var/www
#sudo ln -s /opt/idempiere-builds/idempiere.p2
#sudo ln -s /opt/idempiere-builds/idempiere.migration
#
#sudo nano /etc/apache2/sites-available/000-default.conf
#
#	#Somewhere in your VirtualHost, add the following:
#		<Directory /var/www/idempiere.p2>
#			AllowOverride AuthConfig
#		</Directory>
#
#		<Directory /var/www/idempiere.migration>
#			AllowOverride AuthConfig
#		</Directory>
#
#		Alias /idempiere/p2 /var/www/idempiere.p2
#		Alias /idempiere/migration /var/www/idempiere.migration
#	#end: Somewhere in your VirtualHost, add the following:
#
#sudo /etc/init.d/apache2 restart

#####Configure Jenkins security (performed in jenkins UI)
# In the most recent version of Jenkins, a user is created as part of when Jenkins is first run.
# By default, any user that is logged in as all priviledges. This is OK for many.
# The next section describes how to use matrix based security - offers better user granularity

#####Matrix Based Security (alternative to above)
# Jenkins Menu => Manage Jenkins => Configure Global Security
# Enable Security
# Choose Jenkin's own database
# Uncheck allow users to sign up
# Save - this will prompt you to create a username password
###
# Jenkins Menu => Manage Jenkins => Configure Global Security
# Choose Matrix Based security
# Give Anonymous Overall=>Read; Job=>Read; Job=>Workspace (nothing else - this will make all projects available to ananomous users)
# Add your user => check all check boxes for your user

#####Install Jenkins plugins (performed in jenkins UI)
# www.YourURL.com:8080
# Jenkins Menu => Manage Jenkins => Manage Plugins => Available tab => Choose following plugins => "Install Without Restart"
## required
# (1) buckminster
# (2) mercurial
## optional
# (3) Log Parser - scans logs for known issues - flags the build as a fail if issues found
# (4) Naginator - automatically kicks off a re-build if a fail is encountered. This is helpful if mirrors are acting flakey.

#####Configure Jenkins System (performed in jenkins UI) - Buckminster Version 4.5
# Jenkins Menu => Manage Jenkins => Global Tool Configuration
#   Add Buckminster Button
#   Buckminster Name: buckminster-headless-4.5
#   Install Automatically: no (uncheck)
#   Installation Directory: /opt/buckminster-headless-4.5/
#   Additonal Startup Parameters: -Xmx2g

#####Create New Item (new job in jenkins UI)
# Jenkins Menu => New Item "iDempiere5.1Daily" of type "Build a freestyle Software Project" => OK
#   NO SPACES IN NAME OF JOB!
# Configuration
#  Source Code Management => Mercurial
#    URL: /opt/source/idempiere_source/idempiere
#    Revision Type: revset
#    Revision: pick a specific changeset - this better than just getting what you get from the branch's head  (hg log --limit 1 -- example 11588)
#    Advanced -> check clean build
#  Add below build steps
#    using Buckminster: 4.5

#####Jenkins Build Steps (performed in jenkins UI)
#1 Shell - download common libraries
rpl downloads.sourceforge.net netcologne.dl.sourceforge.net ${WORKSPACE}/org.adempiere.sdk-feature/materialize.properties

#2 Invoke Ant
#Targets:
copy -propertyfile ${WORKSPACE}/org.adempiere.sdk-feature/materialize.properties
#Build File (click advanced button):
${WORKSPACE}/org.adempiere.server-feature/copyjars.xml

#3 Shell - clear workspace
rm -rf ${WORKSPACE}/buckminster.output/
#${WORKSPACE}/buckminster.temp/ ${WORKSPACE}/targetPlatform/

#4 Buckminster - build iDempiere
#Buckminster Installation:
Buckminster Headless 4.5
#Target Platform:
None
#Buckminster Log Level
Debug
#Commands (Note: 5.1 commands changed quite a bit. See previous branches for 4.1 and 3.1 build commands.
importtargetdefinition -A '${WORKSPACE}/org.adempiere.sdk-feature/build-target-platform.target'
import -P ${WORKSPACE}/org.adempiere.sdk-feature/materialize.properties -D 'org.eclipse.buckminster.core.maxParallelMaterializations=5' -D 'org.eclipse.buckminster.core.maxParallelResolutions=1' -D 'org.eclipse.buckminster.download.connectionRetryDelay=5' -D 'org.eclipse.buckminster.download.connectionRetryCount=5' '${WORKSPACE}/org.adempiere.sdk-feature/adempiere.cquery'
build -t
perform -D qualifier.replacement.*=generator:buildTimestamp -D generator.buildTimestamp.format=\'v\'yyyyMMdd-HHmm -D target.os=*       -D target.ws=*     -D target.arch=*      -D product.features=org.idempiere.fitnesse.feature.group,org.idempiere.equinox.p2.director.feature.group -D product.profile=DefaultProfile -D product.id=org.adempiere.server.product,org.eclipse.equinox.p2.director   'org.adempiere.server:eclipse.feature#site.p2'
perform -D qualifier.replacement.*=generator:buildTimestamp -D generator.buildTimestamp.format=\'v\'yyyyMMdd-HHmm -D target.os=linux   -D target.ws=gtk   -D target.arch=x86_64 -D product.features=org.idempiere.fitnesse.feature.group,org.idempiere.equinox.p2.director.feature.group -D product.profile=DefaultProfile -D product.id=org.adempiere.server.product,org.eclipse.equinox.p2.director   'org.adempiere.server:eclipse.feature#create.product.zip'
#Script File (empty field...)

#5 Shell - copy results (site.ps) to webserver - only include this build step if you configured apache above in the "Create web directories publishing p2" step
rm -rf /opt/idempiere-builds/idempiere.p2/*
rm -rf /opt/idempiere-builds/idempiere.migration/*
cp -fR ${WORKSPACE}/buckminster.output/org.adempiere.server_2.1.0-eclipse.feature/site.p2/* /opt/idempiere-builds/idempiere.p2
cp -fR ${WORKSPACE}/migration/* /opt/idempiere-builds/idempiere.migration
cd ${WORKSPACE}
zip -r /opt/idempiere-builds/idempiere.migration/migration.zip migration/
# s3cmd sync ${WORKSPACE}/buckminster.output/org.adempiere.server_2.1.0-eclipse.feature/site.p2/ s3://YourBucket/iDempiere_backup/build/

#####Build Now
# See if she works!!

## NOTE: Here are the steps to configure s3cmd - push to Amazon's AWS S3
## Issue the following commands to enable s3cmd and create an iDempiere backup bucket in S3.
## ----> s3cmd --configure
## --------> get your access key and secred key by logging into your AWS account
## --------> enter a password. Chose something different than your AWS password. Write it down!!
## --------> Accept the default path to GPG
## --------> Answer yes to HTTPS
## ----> s3cmd mb s3://iDempiere_backup
