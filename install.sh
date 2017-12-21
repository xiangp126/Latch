#!/bin/bash

# main work directory, usually ~/myGit
mainWd=~/myGit
# install directory
insDir=~/.usr
# this shell start dir, normally original path
startDir=`pwd`

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
    
    cd $mainWd
    echo cd into  $mainWd/ ...
    
    dirName=ctags
    if [[ -d "$dirName" ]]; then
        echo Removing existing "$dirName"/ ...
        rm -rf $dirName
    fi
    echo git clone https://github.com/universal-ctags/ctags
    git clone https://github.com/universal-ctags/ctags
    
    cd ctags
    echo cd into  "$(pwd)"/ ...
    echo Begin to compile universal ctags ...
    ./autogen.sh
    ./configure --prefix=$insDir
    make -j
    make install
    
    cat << _EOF
    
------------------------------------------------------
ctags path = `which ctags`
------------------------------------------------------
ctags --version

$(ctags --version)

------------------------------------------------------
INSTALLING UNIVERSAL CTAGS Done ...
------------------------------------------------------
_EOF
}

installJava8() {
	echo
}

installTomcat8() {
	# run tomcat using newly made user: tomcat
	tomHome=/opt/tomcat
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
	
	wgetLink="http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.0.48/bin"
	tomV="apache-tomcat-8.0.48.tar.gz"
	echo wget $wgetLink/$tomV
	wget $wgetLink/$tomV

	sudo rm -rf $tomHome
	echo mkdir -p $tomHome
	sudo mkdir -p $tomHome

	# untar into /opt/tomcat and strip one level directory
	sudo tar -zxv -f apache-tomcat-8*tar.gz -C $tomHome --strip-components=1

	cd $tomHome
	echo ------------------------------------------------------
    echo cd into  "$(pwd)"/ ...

	echo chgrp -R tomcat conf
	sudo chgrp -R tomcat conf
	echo chmod g+rwx conf
	sudo chmod g+rwx conf
	echo chmod g+r conf/*
	sudo chmod g+r conf/*
	
	echo chown -R tomcat work/ temp/ logs/
	sudo chown -R tomcat work/ temp/ logs/

	#sudo update-alternatives --config java

	echo cp ${startDir}/tomcat.conf /etc/init/tomcat.conf
	sudo cp ${startDir}/tomcat.conf /etc/init/tomcat.conf

	# change default listen port 8080 to 8081
	echo cp ${startDir}/server.xml /opt/tomcat/conf/server.xml
	sudo cp ${startDir}/server.xml /opt/tomcat/conf/server.xml

	echo ------------------------------------------------------
	echo initctl reload-configuration
	initctl reload-configuration
	# initctl start tomcat
	echo ------------------------------------------------------
}

install() {
	# installCtags
	# installJava8
	installTomcat8
}

case $1 in
    'install')
        install
    ;;

    *)
        usage
    ;;
esac

