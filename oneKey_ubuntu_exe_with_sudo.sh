# For Ubuntu
# 1. Jdk 11 apt-get install
# 2. Tomcat 10 Manual compile and install
# 3. Universal ctags Manual compile and install
#!/bin/bash
# absolute path of this shell, not influenced by the executing dir
mainWd=$(cd $(dirname $0); pwd)
# common install directory
rootInstDir=/opt
commInstdir=$rootInstDir

# daeName=daemon.sh
# daemonPath=$mainWd/$daeName

python3Path=`which python3 2> /dev/null`
# store install summary
summaryTxt=INSTALLATION.TXT
mRunFlagFile=$mainWd/.MORETIME.txt
# store all downloaded packages here
downloadPath=$mainWd/downloads
# store JDK/Tomcat packages
pktPath=$mainWd/packages
loggingPath=$mainWd/log
callIndexerFilePath=$mainWd/callIndexer_exe_with_sudo
isSourceWarDeployed=false

# universal ctags Info
uCtagsInstDir=${commInstdir}/u-ctags

# OpenGrok info globally marked here
OpenGrokVersion=1.12.12
OpenGrokTarName=opengrok-$OpenGrokVersion.tar.gz
OpenGrokUntarName=opengrok-$OpenGrokVersion
OpenGrokDeployMethod=manual
opengrokInstanceBase=/opt/opengrok
dynamicEnvName=dynamic.env
opengrokSrcRoot=${commInstdir}/o-source

# Jdk Info - JDK to be system installed
jdkSystemInstalledVersion=openjdk-11-jdk
jdkInstDir=/usr/lib/jvm/java-11-openjdk-amd64
# /usr/lib/jvm/java-11-openjdk-amd64/bin/java
# /usr/lib/jvm/java-11-openjdk-amd64/bin/javac
javaInstDir=$jdkInstDir
javaPath=$javaInstDir/bin/java
javaVersion=$($javaPath -version)

# Tomcat Info
tomcatInstDir=/opt/tomcat
tomcatStartScript=$tomcatInstDir/bin/startup.sh
tomcatStopScpuript=$tomcatInstDir/bin/shutdown.sh
tomcatUser=`whoami`
tomcatGrp=`whoami`
newListenPort=8080
serverXmlPath=${tomcatInstDir}/conf/server.xml
srvXmlTemplate=$mainWd/template/server.xml

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
    sh $exeName -- setup OpenGrok through one key press

[SYNOPSIS]
    sh $exeName [install | wrapper | summary | help] [PORT]

[EXAMPLE]
    sh $exeName install
    sh $exeName install 8081
    sh $exeName wrapper
    sh $exeName wrapper 8081
    sh $exeName [help]
    sh $exeName summary

[DESCRIPTION]
    install -> instlal OpenGrok using manual deploy method
    wrapper -> install OpenGrok using python wrapper
    summary -> print tomcat/OpenGrok guide and installation info
    help -> print help page
--
    'wrapper' and 'install' mode only differs in OpenGrok deploy method

[TIPS]
    run script needs root privilege but no sudo prefix
    default listen-port is $newListenPort if [PORT] was omitted

_EOF
    logo
}

installuCtags() {
    # check if already installed
    checkCmd=`ctags --version | grep -i universal 2> /dev/null`
    if [[ $checkCmd != "" ]]; then
        uCtagsPath=`which ctags`
        uCtagsBinDir=${uCtagsPath%/*}
        uCtagsInstDir=${uCtagsBinDir%/*}
        return
    fi
    # check if this shell already installed u-ctags
    uCtagsPath=$uCtagsInstDir/bin/ctags
    if [[ -x "$uCtagsPath" ]]; then
        echo "[Warning]: already has u-ctags installed"
        return
    fi
    cat << "_EOF"
------------------------------------------------------
Installing Universal Ctags
------------------------------------------------------
_EOF
    cd $downloadPath
    clonedName=ctags
    if [[ -d "$clonedName" ]]; then
        echo [Warning]: $clonedName/ already exist
    else
        git clone https://github.com/universal-ctags/ctags
        # check if git clone returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: git clone error, quiting now
            exit
        fi
    fi

    cd $clonedName
    # pull the latest code
    git pull
    ./autogen.sh
    ./configure --prefix=$uCtagsInstDir
    make -j
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make error, quitting now
        exit
    fi

    make install
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make install error, quitting now
        exit
    fi
    cat << _EOF
------------------------------------------------------
ctags path = $uCtagsPath
------------------------------------------------------
$($uCtagsPath --version)
_EOF
}

installJdk() {
    cat << "_EOF"
------------------------------------------------------
Installing JDK
------------------------------------------------------
_EOF
    apt-get install $jdkSystemInstalledVersion -y

    cat << _EOF
------------------------------------------------------
java package install path = $javaInstDir
java path = $javaPath
$javaVersion
------------------------------------------------------
_EOF
}

changeListenPort() {
    # restore server.sml to original content
    # srvXmlTemplate=$mainWd/template/server.xml
    cp $srvXmlTemplate $serverXmlPath

    # change listen port if not the default value, passed as $1
    if [[ "$1" != "" && "$1" != 8080 ]]; then
        newListenPort=$1
        cat << _EOF
------------------------------------------------------
Changing Listen Port from Default 8080 to $newListenPort
------------------------------------------------------
_EOF
        sed -i --regexp-extended \
            "s/(<Connector port=)\"8080\"/\1\"${newListenPort}\"/" \
            $serverXmlPath
        # check if returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: change listen port failed, quitting now
            exit
        fi
    fi
}

installTomcat() {
    cat << "_EOF"
------------------------------------------------------
Installing Tomcat
------------------------------------------------------
_EOF
    # check, if jsvc already compiled, return
    jsvcPath=$tomcatInstDir/bin/jsvc
    if [[ -x $jsvcPath ]]; then
        # copy template server.xml to replace old version
        # serverXmlPath=${tomcatInstDir}/conf/server.xml
        if [[ ! -f $serverXmlPath ]]; then
            echo [Error]: missing $serverXmlPath, please check it
            exit 255
        fi
        # already has tomcat installed
        return
    fi

    wgetLink=https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.11/bin/apache-tomcat-10.1.11.tar.gz
    tomcatVersion=apache-tomcat-10.1.11
    tarName=${tomcatVersion}.tar.gz

    cd $mainWd
    if [[ -f "$tarName" ]]; then
        echo "File already exist. Skipping download."
    else
        wget $wgetLink
    fi

    # untar into /opt/tomcat and strip one level directory
    if [[ ! -d $tomcatInstDir ]]; then
        mkdir -p $tomcatInstDir
        tar -zxv -f $tarName --strip-components=1 -C $tomcatInstDir
    fi
    # check if untar returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: untar tomcat package error, quitting now
        exit
    fi

    # change owner:group of TOMCAT_HOME
    chown -R $tomcatUser:$tomcatGrp $tomcatInstDir
    cd $tomcatInstDir
    chmod 775 conf
    chmod g+r conf/*

    # change listen port if not the default value, passed as $1
    # changeListenPort $1

    # start tomcat
    # $tomcatInstDir/bin/startup.sh

    # # make daemon script to start/stop Tomcat
    # cd $mainWd
    # # template script to copy from
    # daemonTemplate=./template/daemon.sh
    # # rename this script to
    # if [[ ! -f $daeName ]]; then
    #     cp $daemonTemplate $daemonPath
    #     # add source command at top of script daemon.sh
    #     sed -i "2a source ${mainWd}/${dynamicEnvName}" $daemonPath
    # fi
    # # check if returns successfully
    # if [[ $? != 0 ]]; then
    #     echo [Error]: make daemon.sh error, quitting now
    #     exit
    # fi

    cat << _EOF
------------------------------------------------------
Start to Compiling Jsvc
------------------------------------------------------
_EOF
    chmod 755 $tomcatInstDir/bin
    cd $tomcatInstDir/bin
    jsvcTarName=commons-daemon-native.tar.gz
    jsvcUntarName=commons-daemon-1.3.4-native-src
    # jsvcUntarName=commons-daemon-1.0.15-native-src
    if [[ ! -f $jsvcTarName ]]; then
        echo [Error]: $jsvcTarName not found, wrong tomcat package downloaded
        exit
    fi
    if [[ ! -d $jsvcUntarName ]]; then
        tar -zxv -f $jsvcTarName
    fi
    chmod -R 777 $jsvcUntarName

    # enter into commons-daemon-1.1.0-native-src
    cd $jsvcUntarName/unix
    sh support/buildconf.sh
    ./configure --with-java=${javaInstDir}
    if [[ $? != 0 ]]; then
        echo [Error]: ./configure jsvc error, quitting now
        exit 255
    fi
    make -j
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make error, quitting now
        exit 255
    fi

    cp jsvc ${tomcatInstDir}/bin
    # jsvcPath=$tomcatInstDir/bin/jsvc
    ls -l $jsvcPath
    if [[ $? != 0 ]]; then
        echo [Error]: check jsvc path error, quitting now
        exit
    fi
    # change owner of jsvc
    cd $tomcatInstDir/bin
    chown -R $newUser:$newGrp jsvc
    # remove jsvc build dir
    rm -rf $jsvcUntarName
}

makeDynEnv() {
    cat << _EOF
------------------------------------------------------
Making Dynamic Environment File for Sourcing
------------------------------------------------------
_EOF
    cd $mainWd
    JAVA_HOME=$javaInstDir
    TOMCAT_HOME=${tomcatInstDir}
    CATALINA_HOME=$TOMCAT_HOME
    # parse value of $var
    cat > $dynamicEnvName << _EOF
#!/bin/bash
export COMMON_INSTALL_DIR=$commInstdir
export UCTAGS_INSTALL_DIR=$uCtagsInstDir
export JAVA_HOME=${JAVA_HOME}
export JRE_HOME=${JAVA_HOME}
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
# export OPENGROK_GENERATE_HISTORY=off
export OPENGROK_CTAGS=$uCtagsPath
_EOF
    # do not parse value of $var
    cat >> $dynamicEnvName << "_EOF"
export PATH=${JAVA_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
_EOF
    chmod +x $dynamicEnvName
}

installOpenGrok() {
    cat << _EOF
------------------------------------------------------
Installing OpenGrok Version $OpenGrokVersion
------------------------------------------------------
_EOF
    wgetLink=https://github.com/oracle/opengrok/releases/download/$OpenGrokVersion
    # OpenGrokTarName=opengrok-$OpenGrokVersion.tar.gz
    # OpenGrokUntarName=opengrok-$OpenGrokVersion

    opengropPath=$downloadPath/$OpenGrokUntarName
    sourceWarPath=$tomcatInstDir/webapps/source.war
    ls -l $sourceWarPath 2> /dev/null
    if [[ $? == 0 ]]; then
        echo "[Warning]: already has source.war deployed, skip"
        isSourceWarDeployed=true
    fi

    cd $downloadPath
    # check if already has tar ball downloaded
    if [[ -f $OpenGrokTarName ]]; then
        echo [Warning]: Tar Ball $tarName already exist
    else
        wget --no-cookies \
            --no-check-certificate \
            --header "Cookie: oraclelicense=accept-securebackup-cookie" \
            "${wgetLink}/${OpenGrokTarName}" \
            -O $OpenGrokTarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo "wget OpenGrok version $OpenGrokVersion failed"
            exit 10
        fi
    fi

    if [[ ! -d $OpenGrokUntarName ]]; then
        tar -zxv -f $OpenGrokTarName
    fi

    # call func makeDynEnv -- for legacy bash OpenGrok
    makeDynEnv

    # build OpenGrok python tools -- optional
    # buildPythonTools

    deployOpenGrok

    # fix one warning
    mkdir -p ${opengrokInstanceBase}/{src,data,etc}
    cp -f $downloadPath/$OpenGrokUntarName/doc/logging.properties \
                 ${opengrokInstanceBase}/logging.properties
    # mkdir opengrok SRC_ROOT if not exist
    mkdir -p $opengrokSrcRoot
    srcRootUser=`whoami 2> /dev/null`
    if [[ '$srcRootUser' != '' ]]; then
        chown -R $srcRootUser $opengrokSrcRoot
        chown -R $srcRootUser $opengrokInstanceBase
    fi

    # generating index
    callIndexer
}

# callIndexer <OpenGrokUntarName>
callIndexer() {
    cat << "_EOF"
------------------------------------------------------
Prepare to Call Indexer
------------------------------------------------------
_EOF
    # $mainWd/downloads/opengrok-1.1-rc74
    opengropPath=$downloadPath/$OpenGrokUntarName
    # /usr/local/bin/opengrok-indexer
    # opengrokIndexerPath=`which opengrok-indexer 2> /dev/null`
    # if [[ "$opengrokIndexerPath" == "" ]]; then
    #     echo [Warning]: No opengrok-indexer found, nothing matter
    # fi

    propertyFile=$opengrokInstanceBase/logging.properties
    # The indexer can be run either using opengrok.jar directly:
    javaIndexerCommand=$(echo $javaPath \
        -Djava.util.logging.config.file=$propertyFile \
        -jar $opengropPath/lib/opengrok.jar \
        -c $uCtagsPath \
        -s $opengrokSrcRoot \
        -d $opengrokInstanceBase/data -H -P -S -G \
        -W $opengrokInstanceBase/etc/configuration.xml)

    # or using the opengrok-indexer wrapper like so:
    wrapperIndexerCommand=$(echo $opengrokIndexerPath \
        -J=-Djava.util.logging.config.file=$propertyFile \
        -j $javaPath \
        -a $opengropPath/lib/opengrok.jar -- \
        -c $uCtagsPath \
        -s $opengrokSrcRoot \
        -d $opengrokInstanceBase/data -H -P -S -G \
        -W $opengrokInstanceBase/etc/configuration.xml)

    # save indexer commands into a file
    makeIndexerFile

    # opengrok-indexer will generate opengrok0.0.log
    # leaving them into log directory
    cd $loggingPath
    cat << "_EOF"
------------------------------------------------------
Generating Index using Java/Wrapper Indexer Command
------------------------------------------------------
_EOF
    $javaIndexerCommand

    if [[ $? != 0 ]]; then
        echo Generating index failed
        exit 1
    fi
}

# save indexer commands into a shell
makeIndexerFile() {
    cat << "_EOF"
------------------------------------------------------
Saving Indexer Commands into Bash Script
------------------------------------------------------
_EOF
    # $wrapperIndexerCommand was set in func: installOpenGrok
    cat << _EOF > $callIndexerFilePath
#/bin/bash
set -x
cd $loggingPath
# The indexer can be run using java directly
$javaIndexerCommand

$tomcatStopScpuript
$tomcatStartScript
_EOF
    chmod +x $callIndexerFilePath
}

# deployOpenGrok <OpenGrokUntarName>
deployOpenGrok() {
    cat << "_EOF"
------------------------------------------------------
Deploy OpenGrok Without Any Other Tools
------------------------------------------------------
_EOF
    if [[ "$isSourceWarDeployed" == "true" ]]; then
        return
    fi

    if [[ "$OpenGrokDeployMethod" == "wrapper" ]]; then
        # deploy OpenGrok using opengrok-deploy
        pythonDeployBinPath=`which opengrok-deploy 2> /dev/null`
        configPath=$opengrokInstanceBase/etc/configuration.xml

        # Example:
        # sudo opengrok-deploy -c /opt/opengrok/etc/configuration.xml \
        #         downloads/opengrok-1.1-rc74/lib/source.war \
        #         /usr/local/Cellar/tomcat/9.0.12/libexec/webapps
        $pythonDeployBinPath -c $configPath \
                $opengropPath/lib/source.war $tomcatInstDir/webapps
        if [[ $? != 0 ]]; then
            echo deploy OpenGrok using wrapper failed
            exit 5
        fi
    else
        # deploy OpenGrok manually, without any tools
        warPrefix=source
        # $mainWd/downloads/opengrok-1.1-rc74
        opengropPath=$downloadPath/$OpenGrokUntarName
        warPath=$opengropPath/lib/$warPrefix.war
        webappsDir=$tomcatInstDir/webapps
        webXmlName=web.xml
        webXmlDir=$tomcatInstDir/$warPrefix/WEB-INF
        webXmlPath=$webXmlDir/$webXmlName

        # copy source.war to tomcat webapps
        cp $warPath $webappsDir
        if [[ $? != 0 ]]; then
            copy $warPrefix.war to tomcat failed
            exit 5
        fi

        # If user does not use default OPENGROK_INSTANCE_BASE then attempt to
        # extract WEB-INF/web.xml from source.war using jar or zip utility, update
        # the hardcoded values and then update source.war with the new
        # WEB-INF/web.xml.
        if [[ "$opengrokInstanceBase" != "/var/opengrok" ]]; then
            cd $webappsDir
            mkdir $warPrefix
            # tar -xvf $warPrefix.war -C $warPrefix
            unzip $warPrefix.war -d $warPrefix
            if [[ $? != 0 ]]; then
                echo "untar $warPrefix.war failed"
                exit 5
            fi
            cd $warPrefix/WEB-INF
            configXmlPath=$opengrokInstanceBase/etc/configuration.xml
            sed -e 's:/var/opengrok/etc/configuration.xml:'"$configXmlPath"':g' \
                $webXmlName > $webXmlName.tmp
            mv $webXmlName.tmp $webXmlName
            cd $webappsDir
            tar -zcvf $warPrefix.war $warPrefix
        fi

        if [[ $? != 0 ]]; then
            echo deploy OpenGrok manually, without any tools failed
            exit 6
        fi
    fi
}

buildPythonTools() {
    cat << "_EOF"
------------------------------------------------------
Building OpenGrok Python Tools
------------------------------------------------------
_EOF
    # $mainWd/downloads/opengrok-1.1-rc74
    opengropPath=$downloadPath/$OpenGrokUntarName

    # check python3 env
    python3Path=`which python3 2> /dev/null`
    pythonDeployBinPath=`which opengrok-deploy 2> /dev/null`
    if [[ "$pythonDeployBinPath" == "" ]]; then
        if [[ "$python3Path" == "" ]]; then
            echo check your python3 env first
            exit 12
        fi

        # check pip env
        pipPath=`which pip 2>/dev/null`
        if [[ "$pipPath" == "" ]]; then
            # install pip
            curl https://bootstrap.pypa.io/get-pip.py | sudo python3
            if [[ $? != 0 ]]; then
                echo install pip failed
                echo apt-get install python3-pip
                exit
            fi
        fi

        # install python tools
        cd $opengropPath
        cd tools
        python3 -m pip install opengrok-tools.tar.gz
        # sudo python3 -m pip uninstall opengrok-tools
        if [[ $? != 0 ]]; then
            echo install OpenGrok python tools failed
            exit 2
        fi
    fi
}

installSummary() {
    cat > $summaryTxt << _EOF

---------------------------------------- Summary ----
Universal Ctags Path = $uCtagsPath
Java Path = $javaPath
jsvc path = $jsvcPath
Java Home = $javaInstDir
Tomcat Home = $tomcatInstDir
Opengrok Instance Base = $opengrokInstanceBase
Opengrok Source Root = $opengrokSrcRoot
Browser Site: http://127.0.0.1:${newListenPort}/source
_EOF
    cat >> $summaryTxt << _EOF
---------------------------------------- Indexer ----
$callIndexerFilePath
-----------------------------------------------------
_EOF
    cat $summaryTxt
}

printSummary() {
    if [[ $platCategory = "linux" ]]; then
        cat << _EOF
-------------------------------------------------
Tomcat Version 8 User Guide
-------------------------------------------------
-- Under $mainWd
# start tomcat
sudo ./daemon.sh start
or
sudo ./daemon.sh run
sudo ./daemon.sh run &> /dev/null &
# stop tomcat
sudo ./daemon.sh stop
-------------------------------------------------
OpenGrok Version $OpenGrokVersion Guide -- Legacy
-------------------------------------------------
-- Under ./downloads/opengrok-1.1-rc17/bin
# deploy OpenGrok
sudo ./OpenGrok deploy

# if make soft link of source to SRC_ROOT
# care for Permission of SRC_ROOT for user: $tomcatUser
cd $opengrokSrcRoot
sudo ln -s /usr/local/src/* .

# make index of source (multiple index)
sudo ./OpenGrok index [$opengrokSrcRoot]
                       /opt/source   -- proj1
                                     -- proj2
                                     -- proj3
--------------------------------------------------------
-- Guide to Change Listen Port
# replace s/original/8080/ to the port you want to change
sudo sed -i 's/${newListenPort}/8080/' $serverXmlPath
sudo ./daemon.sh stop
sudo ./daemon.sh start
------------------------------------------------------
_EOF
    fi
    if [[ -f $summaryTxt ]]; then
        cat $summaryTxt
    fi
}

#start web service
tackleWebService() {
    # restart tomcat daemon underground
    cd $mainWd
    cat << _EOF
--------------------------------------------------------
Stop Tomcat Web Service
--------------------------------------------------------
_EOF
    $tomcatStopScript
    retVal=$?
    # just print warning
    if [[ $retVal != 0 ]]; then
        set +x
        echo [Warning]: Tomcat stop returns value: $retVal
    fi 

    cat << _EOF
--------------------------------------------------------
Start Tomcat Web Service
--------------------------------------------------------
_EOF
    $tomcatStartScript
    retVal=$?
    # just print warning
    if [[ $retVal != 0 ]]; then
        echo [Warning]: Tomcat start returns value: $retVal
    fi
}

preInstallForLinux() {
    cat << _EOF
--------------------------------------------------------
Pre Install Tools for Linux
--------------------------------------------------------
_EOF

apt-get install \
    pkg-config libevent-dev build-essential cmake \
    automake curl autoconf libtool sshfs python3 \
    net-tools  -y
}

install() {
    mkdir -p $downloadPath
    mkdir -p $loggingPath

    preInstallForLinux
    installJdk
    installTomcat

    # begin of common install part
    # changeListenPort $1
    installuCtags
    installOpenGrok
    # end of common install part

    tackleWebService
    installSummary
}

case $1 in
    'install')
        set -x
        install $2
        ;;

    'wrapper')
        set -x
        OpenGrokDeployMethod=wrapper
        install $2
        ;;

    "summary")
        set +x
        printSummary
        ;;

    *)
        set +x
        usage
        ;;
esac
