#!/bin/bash
# this shell start dir, normally original path
startDir=`pwd`
# main work directory, usually ~/myGit/XX
mainWd=$startDir
# common install directory
rootInstDir=/opt
commInstdir=$rootInstDir
#execute prefix: sudo
execPrefix="sudo"
#universal ctags install dir
uCtagsInstDir=${commInstdir}/u-ctags
javaInstDir=/opt/java8
tomcatInstDir=/opt/tomcat8
# default new listen port is 8080
newListenPort=8080
# dynamic env global name
dynamicEnvName=dynamic.env
opengrokInstanceBase=/opt/opengrok
opengrokSrcRoot=${commInstdir}/o-source
OPENGROKPATH=""
# id to run tomcat
tomcatUser=tomcat8
tomcatGrp=tomcat8

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
    sh $exeName -- setup opengrok through one script
                | shell need root privilege, but 
                | no need run with sudo prefix

[USAGE]
    #default Listen-Port is $newListenPort if para was omitted
    $exeName [install | help] [Listen-Port]

_EOF
    logo
}

installCtags() {
    uCtagsPath=$uCtagsInstDir/bin/ctags
    if [[ -x "$uCtagsPath" ]]; then
        echo "[Warning]: already has u-ctags installed, omitting this step ..."
        return
    fi
    cat << "_EOF"
------------------------------------------------------
STEP 1: INSTALLING UNIVERSAL CTAGS ...
------------------------------------------------------
_EOF
    CTAGS_HOME=$uCtagsInstDir

    cd $startDir
    clonedName=ctags
    if [[ -d "$clonedName" ]]; then
        echo [Warning]: $clonedName/ already exists, omitting this step ...
    else
        git clone https://github.com/universal-ctags/ctags
        # check if git clone returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: git clone returns error, quiting now ...
            exit
        fi
    fi
    
    cd $clonedName
    ./autogen.sh
    ./configure --prefix=$uCtagsInstDir
    make -j
	# check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quitting now ...
        exit
    fi

    $execPrefix make install
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make install returns error, quitting now ...
        exit
    fi
    cat << _EOF
------------------------------------------------------
ctags path = $uCtagsInstDir/bin/ctags
------------------------------------------------------
$($uCtagsInstDir/bin/ctags --version)
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
    wgetLink=http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808
    tarName=jdk-8u161-linux-x64.tar.gz
    #untarName=jdk1.8.0_161

    # rename download package
    cd $startDir
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, omitting wget ...
    else
        wget --no-cookies \
             --no-check-certificate \
             --header "Cookie: oraclelicense=accept-securebackup-cookie" \
             "${wgetLink}/${tarName}" \
             -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi
    if [[ ! -d $javaInstDir ]]; then
        $execPrefix mkdir -p $javaInstDir
        $execPrefix tar -zxv -f $tarName --strip-components=1 -C $javaInstDir
        # no more need make soft link for java, will added in PATH
        # ln -sf ${javaInstDir}/bin/java ${commInstdir}/bin/java 
    fi
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: untar java package returns error, quitting now ...
        exit
    fi
    checkName=$javaInstDir/bin/java
    if [[ ! -x $checkName ]]; then
        echo [Error]: java install error, quitting now ...
        exit
    fi
    cat << _EOF
------------------------------------------------------
java package install path = $javaInstDir
java path = $javaInstDir/bin/java
$($javaInstDir/bin/java -version)
------------------------------------------------------
_EOF
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
    cd - &> /dev/null
}

installTomcat8() {
    cat << "_EOF"
------------------------------------------------------
STEP 3: INSTALLING TOMCAT 8 ...
------------------------------------------------------
_EOF
	# run tomcat using newly made user: tomcat
	newUser=$tomcatUser
	newGrp=$tomcatGrp
	# tomcat:tomcat
	# create group if not exists  
	egrep "^$newGrp" /etc/group &> /dev/null
	if [[ $? = 0 ]]; then  
		echo [Warning]: group $newGrp already exists ...
	else
		$execPrefix groupadd $newUser
	fi
	# create user if not exists  
	egrep "^$newUser" /etc/passwd &> /dev/null
	if [[ $? = 0 ]]; then  
		echo [Warning]: group $newGrp already exists ...
	else 
		$execPrefix useradd -s /bin/false -g $newGrp -d $tomcatInstDir $newUser
	fi
	
    #begin download issue
    wgetLink=http://mirror.olnevhost.net/pub/apache/tomcat/tomcat-8/v8.5.24/bin
    tarName=apache-tomcat-8.5.24.tar.gz

    cd $startDir
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, omitting wget ...
    else
        wget --no-cookies \
  	         --no-check-certificate \
  	         --header "Cookie: oraclelicense=accept-securebackup-cookie" \
  	         "${wgetLink}/${tarName}" \
  	         -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi
	# untar into /opt/tomcat and strip one level directory
    if [[ ! -d $tomcatInstDir ]]; then
        $execPrefix mkdir -p $tomcatInstDir
        $execPrefix tar -zxv -f $tarName --strip-components=1 -C $tomcatInstDir 
    fi
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: untar tomcat package error, quitting now ...
        exit
    fi

    # change owner:group of TOMCAT_HOME
    $execPrefix chown -R $newUser:$newGrp $tomcatInstDir
	cd $tomcatInstDir
	$execPrefix chmod 775 conf
	$execPrefix chmod g+r conf/*

	# echo ------------------------------------------------------
    # echo START TO MAKE TOMCAT CONF FILE ...
	# echo ------------------------------------------------------
    # writeTomcatConf
    # $execPrefix echo  cp ${startDir}/tomcat.conf /etc/init/tomcat.conf

    #check if listen-port was passed as $1 argument
    if [[ "$1" != "" ]]; then
        newListenPort=$1
    fi

    # do the sed routine only if newListenPort != default port
    if [[ "$newListenPort" != 8080 ]]; then
    	echo ------------------------------------------------------
    	echo change default listen port 8080 to $newListenPort ...
        serverXmlPath=${tomcatInstDir}/conf/server.xml
        $execPrefix cp $serverXmlPath ${serverXmlPath}.bak
        $execPrefix sed -i --regexp-extended \
             "s/(<Connector port=)\"8080\"/\1\"${newListenPort}\"/" \
             $serverXmlPath
    	echo ------------------------------------------------------
    fi
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: change listen port error, quitting now ...
        exit
    fi

    # make daemon script to start/shutdown Tomcat
    cd $startDir
    envName=$dynamicEnvName
    #sample/template script to copy from
    smpScripName=./template/daemon.sh.template
    # copied to name
    daeName=daemon.sh
    cp $smpScripName $daeName
    # add source command at top of script daemon.sh
    sed -i "2a source ${startDir}/${envName}" $daeName
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: sed returns error, quitting now ...
        exit
    fi
    cat << _EOF
------------------------------------------------------
START TO COMPILING JSVC ...
------------------------------------------------------
_EOF
    $execPrefix chmod 755 $tomcatInstDir/bin
    cd $tomcatInstDir/bin
    tarName=commons-daemon-native.tar.gz
    untarName=commons-daemon-1.1.0-native-src
    if [[ ! -f $tarName ]]; then
        echo [Error]: $tarName not found, wrong tomcat package downloaded ...
        exit
    fi
    if [[ ! -d $untarName ]]; then
        $execPrefix tar -zxv -f $tarName
    fi
    $execPrefix chmod -R 777 $untarName

    #go into commons-daemon-1.1.0-native-src
    cd $untarName/unix
    sh support/buildconf.sh
    ./configure --with-java=${javaInstDir}
    if [[ $? != 0 ]]; then
        echo [Error]: ./configure returns error, quitting now ...
        exit
    fi
    make -j
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quitting now ...
        exit
    fi

    $execPrefix cp jsvc ${tomcatInstDir}/bin
    cd $tomcatInstDir/bin
    $execPrefix chown -R $newUser:$newGrp jsvc
    # $execPrefix rm -rf $untarName

    # cd $startDir
    # echo Stop Tomcat Daemon ...
    # $execPrefix sh ./daemon.sh stop &> /dev/null
    # echo Start Tomcat Daemon ...
    # $execPrefix sh ./daemon.sh run &> /dev/null &
}

makeDynEnv() {
    # enter into dir first
    cd $startDir
    envName=dynamic.env
    TOMCAT_HOME=${tomcatInstDir}
    CATALINA_HOME=$TOMCAT_HOME

    # parse value of $var
    cat > $envName << _EOF
#!/bin/bash
export COMMON_INSTALL_DIR=$commInstdir
export CTAGS_INSTALL_DIR=${uCtagsInstDir}/bin
export JAVA_HOME=${javaInstDir}
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export TOMCAT_USER=${tomcatUser}
export TOMCAT_HOME=${TOMCAT_HOME}
export CATALINA_HOME=${TOMCAT_HOME}
export CATALINA_BASE=${TOMCAT_HOME}
export CATALINA_TMPDIR=${TOMCAT_HOME}/temp
export OPENGROK_INSTANCE_BASE=${opengrokInstanceBase}
export OPENGROK_TOMCAT_BASE=$CATALINA_HOME
export OPENGROK_SRC_ROOT=$opengrokSrcRoot
# export OPENGROK_WEBAPP_CONTEXT=ROOT
export OPENGROK_CTAGS=${uCtagsInstDir}/bin/ctags
_EOF
    # do not parse value of $var
    cat >> $envName << "_EOF"
export PATH=${JAVA_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
_EOF
    chmod +x $envName
    cd - &> /dev/null
    # as return value of this func
    echo $envName
}

# deploy OpenGrok
installOpenGrok() {
    cat << "_EOF"
------------------------------------------------------
STEP 4: INSTALLING OPENGROK ...
------------------------------------------------------
_EOF
    wgetLink=https://github.com/oracle/opengrok/releases/download/1.1-rc17
    tarName=opengrok-1.1-rc17.tar.gz
    untarName=opengrok-1.1-rc17

    cd $startDir
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, omitting wget ...
    else
        wget --no-cookies \
        --no-check-certificate \
        --header "Cookie: oraclelicense=accept-securebackup-cookie" \
        "${wgetLink}/${tarName}" \
        -O $tarName

        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi

    if [[ ! -d $untarName ]]; then
        tar -zxv -f $tarName 
    fi
    cat << _EOF
------------------------------------------------------
MAKEING DYNAMIC ENVIRONMENT FILE FOR SOURCE ...
------------------------------------------------------
_EOF
    # call func makeDynEnv
    makeDynEnv
    envName=$dynamicEnvName

    # source ./$envName
    # enter into opengrok dir
    cd $untarName/bin
    #OpenGrok executable file name is OpenGrok
    ogExecFile=OpenGrok
    # add write privilege to it.
    chmod +w $ogExecFile
    OPENGROKPATH=`pwd`

    # add source command on top of script OpenGrok
    # notice double quotation marks
    sed -i "2a source ${startDir}/${envName}" OpenGrok
    $execPrefix ./$ogExecFile deploy
    # [Warning]: OpenGrok can not be well executed in other location.
    # ln -sf "`pwd`"/OpenGrok ${commInstdir}/bin/openGrok 

    # fix one warning
    $execPrefix mkdir -p ${opengrokInstanceBase}/src
    $execPrefix cp -f ../doc/logging.properties \
                 ${opengrokInstanceBase}/logging.properties
    # mkdir opengrok SRC_ROOT if not exist
    $execPrefix mkdir -p $opengrokSrcRoot
}

installSummary() {
    cat << _EOF
------------------------------------------------------
INSTALLATION SUMMARY
------------------------------------------------------
universal ctags path = ${uCtagsInstDir}/bin/ctags
java path = $javaInstDir/bin/java
jsvc path = $tomcatInstDir/bin/jsvc
java home = $javaInstDir
tomcat home = $tomcatInstDir
opengrok instance base = $opengrokInstanceBase
opengrok source root = $opengrokSrcRoot
http://127.0.0.1:${newListenPort}/source
------------------------------------------------------
_EOF
}

printHelpPage() {
    cat << _EOF
-------------------------------------------------
FOR TOMCAT 8 HELP
-------------------------------------------------
-- Under $startDir
# start tomcat
sudo ./daemon.sh start
or
sudo ./daemon.sh run 
sudo ./daemon.sh run &> /dev/null &
# stop tomcat
sudo ./daemon.sh stop
-------------------------------------------------
FOR OPENGROK HELP
-------------------------------------------------
-- Under ./opengrok-1.1-rc17/bin
# deploy OpenGrok
sudo ./OpenGrok deploy

# make soft link of source to SRC_ROOT
# care for Permission of SRC_ROOT for user: $tomcatUser
cd $opengrokSrcRoot
sudo ln -s /usr/local/src/* .

# make index of source (multiple index)
sudo ./OpenGrok index [$opengrokSrcRoot]
                       /opt/source   -- proj1
                                     -- proj2 
                                     -- proj3 
--------------------------------------------------------
-- GUIDE TO CHANGE LISTEN PORT ...
# replace s/original/8080/ to the port you want to change
sudo sed -i 's/${newListenPort}/8080/' $serverXmlPath
sudo ./daemon.sh stop
sudo ./daemon.sh start
------------------------------------------------------
_EOF
}

#start web service
tackleWebService() {
    # restart tomcat daemon underground
    cd $startDir
    cat << _EOF
--------------------------------------------------------
STOP TOMCAT DAEMON ALREADY RUNNING ...
--------------------------------------------------------
_EOF
    # sudo ./daemon.sh stop
    # if [[ $? != 0 ]]; then
    #     echo [Error]: Tomcat threads stop failed, exit now ...
    #     exit
    # fi
    # root   70057  431  0.1 38846760 318236 pts/39 Sl  05:36   0:08 jsvc.
    tomcatThreads=`ps aux | grep -i tomcat | grep -i jsvc.exec | tr -s " " \
        | cut -d " " -f 2`
    # use kill to stop tomcat living threads if daemon stop failed
    if [[ "$tomcatThreads" != "" ]]; then
        for thread in ${tomcatThreads[@]}
        do
            $execPrefix kill -9 $thread
        done
    fi
    if [[ $? != 0 ]]; then
        echo [Error]: Tomcat threads stop failed, exit now ...
        exit
    fi
    cat << _EOF
--------------------------------------------------------
START TOMCAT WEB SERVICE ...
--------------------------------------------------------
_EOF
    sleep 2
    #try some times to start tomcat web service
    for (( i = 0; i < 3; i++ )); do
        $execPrefix ./daemon.sh start
        if [[ $? != 0 ]]; then
            echo [Error]: Tomcat start failed $(echo $i + 1 | bc) time ...
            sleep 1
        else
            echo "Tomcat started successfully ..."
            return
        fi
    done
    #start failed at last
    echo "You should manually start tomcat daemon sudo ./daemon.sh start"
    exit
}

install() {
    installCtags
	installJava8
    #$1 passed as new listen port
	installTomcat8 $1
    installOpenGrok
    tackleWebService
    installSummary
}

case $1 in
    'install')
        set -x
        install $2
    ;;

    "help")
        set +x
        printHelpPage
    ;;

    *)
        set +x
        usage
    ;;
esac
