#!/bin/bash
set -x

# this shell start dir, normally original path
startDir=`pwd`
# main work directory, usually ~/myGit
mainWd=$startDir

# common install directory
commInstdir=~/.usr
ctagsInstDir=$commInstdir
javaInstDir=/usr/lib/jvm/java-8-self
tomcatInstDir=/opt/tomcat8-self

logo() {
    cat << "_EOF"
  ___  _ __   ___ _ __   __ _ _ __ ___ | | __
 / _ \| '_ \ / _ \ '_ \ / _` | '__/ _ \| |/ /
| (_) | |_) |  __/ | | | (_| | | | (_) |   <
 \___/| .__/ \___|_| |_|\__, |_|  \___/|_|\_\
      |_|               |___/

_EOF
}

usage() {

	exeName=${0##*/}
    cat << _EOF
[NAME]
	$exeName -- setup opengrok through one script

[USAGE]
	$exeName [install | help]

_EOF
	logo
}

installCtags() {
    
    cat << "_EOF"
    
------------------------------------------------------
STEP 1: INSTALLING UNIVERSAL CTAGS ...
------------------------------------------------------
_EOF
    CTAGS_HOME=$ctagsInstDir

    cd $mainWd
    echo cd into  $mainWd/ ...
    
    dirName=ctags
    if [[ -d "$dirName" ]]; then
        echo [Warning]: $dirName/ already exists, Omitting this ...
        # echo Removing existing "$dirName"/ ...
        # rm -rf $dirName
    else
        echo git clone https://github.com/universal-ctags/ctags
        cd $startDir
        git clone https://github.com/universal-ctags/ctags
    fi
    
    cd ctags
    echo cd into  "$(pwd)"/ ...
    echo Begin to compile universal ctags ...
    sleep 2
    ./autogen.sh
    ./configure --prefix=$ctagsInstDir
    make -j
    sleep 2
    make install
    
    cat << _EOF
    
------------------------------------------------------
ctags path = `which ctags`
------------------------------------------------------
ctags --version

$(ctags --version)

------------------------------------------------------
INSTALLING UNIVERSAL CTAGS DONE ...
------------------------------------------------------
_EOF
}

installJava8() {
    cat << "_EOF"
    
------------------------------------------------------
STEP 2: INSTALLING JAVA 8 ...
------------------------------------------------------
_EOF
    # instruction to install java8
    JAVA_HOME=$javaInstDir
    local wgetLink=http://javadl.oracle.com/webapps/download/AutoDL?BundleId=227542_e758a0de34e24606bca991d704f6dcbf
    tarName=jre-8u151-linux-x64.tar.gz

    # make new directory if not exist
    sudo mkdir -p $javaInstDir

    # rename download package
    cd $startDir
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, Omitting wget ...
    else
        wget $wgetLink -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi

    sudo tar -zxv -f "$tarName" --strip-components=1 -C $javaInstDir
    ln -sf ${javaInstDir}/bin/java ${commInstdir}/bin/java 

    cat << _EOF
    
------------------------------------------------------
STEP 2: INSTALLING JAVA 8 DONE ...
_EOF
    echo java -version
    java -version
    echo ------------------------------------------------------
}

writeTomcatConf() {
    # tomcat start/stop conf name
    confFile=tomcat.conf
    TOM_HOME=$tomcatInstDir
    CATALINA_HOME=$tomcatInstDir

    cd $mainWd
    cat > "$confFile" << _EOF
description "Tomcat Server"

  start on runlevel [2345]
  stop on runlevel [!2345]
  respawn
  respawn limit 10 5

  setuid tomcat
  setgid tomcat

  env JAVA_HOME=$JAVA_HOME
  env CATALINA_HOME=$TOM_HOME

  # Modify these options as needed
  env JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
  env CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

  exec $CATALINA_HOME/bin/catalina.sh run

  # cleanup temp directory after stop
  post-stop script
    rm -rf $CATALINA_HOME/temp/*
  end script
_EOF
    cd -
}

installTomcat8() {
    cat << "_EOF"
    
------------------------------------------------------
STEP 3: INSTALLING TOMCAT 8 ...
------------------------------------------------------
_EOF
	# run tomcat using newly made user: tomcat
    tomHome=$tomcatInstDir
	newUser=tomcat
	newGrp=tomcat

	# tomcat:tomcat
	# create group if not exists  
	egrep "^$newGrp" /etc/group &> /dev/null
	if [[ $? = 0 ]]; then  
		echo [Warning]: group $newGrp already exists ...
	else
		echo groupadd $newUser
		sudo groupadd $newUser
	fi

	# create user if not exists  
	egrep "^$newUser" /etc/passwd &> /dev/null
	if [[ $? = 0 ]]; then  
		echo [Warning]: group $newGrp already exists ...
	else 
		echo useradd -s /bin/false -g $newGrp -d $tomHome $newUser
		sudo useradd -s /bin/false -g $newGrp -d $tomHome $newUser
	fi
	
	wgetLink="http://mirror.jax.hugeserver.com/apache/tomcat/tomcat-8/v8.5.24/bin"
	tarName="apache-tomcat-8.5.24.tar.gz"

    cd $startDir
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, Omitting wget ...
    else
        wget $wgetLink -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi

	sudo rm -rf $tomHome
	echo mkdir -p $tomHome
	sudo mkdir -p $tomHome

	# untar into /opt/tomcat and strip one level directory
	sudo tar -zxv -f apache-tomcat-8*tar.gz -C $tomHome --strip-components=1

	cd $tomHome
	echo ------------------------------------------------------
    echo cd into  "$(pwd)"/ ...

	sudo chgrp -R tomcat conf
	sudo chmod g+rwx conf
	sudo chmod g+r conf/*
	sudo chown -R tomcat work/ temp/ logs/

#	sudo update-alternatives --config java
#

    writeTomcatConf
    sudo cp ${startDir}/tomcat.conf /etc/init/tomcat.conf

	echo ------------------------------------------------------
	echo change default listen port 8080 to 8081 ...
    serverXmlPath=${tomHome}/conf/server.xml
    sudo cp $serverXmlPath ${serverXmlPath}.bak
    sudo sed -i --regexp-extended 's/(<Connector port=)"8080"/\1"8081"/' \
        ${serverXmlPath}
	echo ------------------------------------------------------

#	echo initctl reload-configuration
#	sudo initctl reload-configuration
#	initctl start tomcat
#	echo ------------------------------------------------------

    cat << "_EOF"
    
------------------------------------------------------
STEP 3: INSTALLING TOMCAT 8 DONE ...
------------------------------------------------------
_EOF
}

# deploy OpenGrok
installOpenGrok() {
    cat << "_EOF"
    
------------------------------------------------------
STEP 4: INSTALLING OPENGROK ...
------------------------------------------------------
_EOF

    wgetLink="https://github.com/oracle/opengrok/releases/download/1.1-rc18"
    tarName="opengrok-1.1-rc18.tar.gz"

    cd $startDir
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, Omitting wget ...
    else
        wget $wgetLink -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi

    tar -zxv -f $tarName 
    cd $tarName

    cat << "_EOF"
    
------------------------------------------------------
STEP 4: INSTALLING OPENGROK DONE ...
------------------------------------------------------
_EOF
}

summaryInstall() {
    set +x
    logo

    cat << _EOF

------------------------------------------------------
universal ctags under: `which ctags`
------------------------------------------------------

------------------------------------------------------
# java8 under: `which java`
export JAVA_HOME=${javaInstDir}
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
------------------------------------------------------

------------------------------------------------------
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export CATALINA_HOME=/opt/tomcat
export OPENGROK_TOMCAT_BASE=$CATALINA_HOME
------------------------------------------------------
_EOF
}

install() {
	installCtags
    sleep 2
	installJava8
    sleep 2
	installTomcat8
    sleep 2
    installOpenGrok

    # show install summary
    sleep 2
    summaryInstall
}

case $1 in
    'install')
        install
    ;;

    *)
        usage
    ;;
esac
