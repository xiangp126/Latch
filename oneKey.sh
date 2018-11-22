#!/bin/bash
# from which path it was executed
startDir=`pwd`
# absolute path of this shell, not influenced by start dir
mainWd=$(cd $(dirname $0); pwd)
# common install directory
rootInstDir=/opt
commInstdir=$rootInstDir
# execute prefix: sudo
execPrefix="sudo"
# universal ctags install dir
uCtagsInstDir=${commInstdir}/u-ctags
javaInstDir=/opt/java8
tomcatInstDir=/opt/tomcat8
# default new listen port is 8080
newListenPort=8080
serverXmlPath=${tomcatInstDir}/conf/server.xml
srvXmlTemplate=$mainWd/template/server.xml
# dynamic env global name
dynamicEnvName=dynamic.env
opengrokInstanceBase=/opt/opengrok
opengrokSrcRoot=${commInstdir}/o-source
# user and group to own Tomcat install dir
tomcatUser=`whoami`
tomcatGrp=`whoami`
python3Path=`which python3 2> /dev/null`
# store install summary
summaryTxt=INSTALLATION.TXT
mRunFlagFile=$mainWd/.MORETIME.txt
# store all downloaded packages here
downloadPath=$mainWd/downloads
# store JDK/Tomcat packages
pktPath=$mainWd/packages
loggingPath=$mainWd/log
callIndexerFilePath=$mainWd/callIndexer
isSourceWarDeployed=false
# macos | ubuntu | centos
platOsType=macos
# mac | linux
platCategory=mac
# OpenGrok info globally marked here
OpenGrokVersion=1.1-rc74
OpenGrokTarName=opengrok-$OpenGrokVersion.tar.gz
OpenGrokUntarName=opengrok-$OpenGrokVersion
# wrapper/manual -- default manual
OpenGrokDeployMethod=manual

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

# support mac | centos | ubuntu
checkPlatOsType() {
    arch=$(uname -s)
    case $arch in
        Darwin)
            # echo "Platform is MacOS"
            platOsType=macos
            ;;
        Linux)
            linuxType=`sed -n '1p' /etc/issue | tr -s " " | cut -d " " -f 1`
            if [[ "$linuxType" == "Ubuntu" ]]; then
                # echo "Platform is Ubuntu"
                platOsType=ubuntu
            elif [[ "$linuxType" == "CentOS" || "$linuxType" == "\S" ]]; then
                # echo "Platform is CentOS" \S => CentOS 7
                platOsType=centos
            elif [[ $linuxType == "Red" ]]; then
                # echo "Platform is Red Hat"
                platOsType=centos
            elif [[ $linuxType == "Raspbian" ]]; then
                # echo "Platform is Raspbian"
                platOsType=ubuntu
            else
                echo "Sorry, We did not support your platform, pls check it first"
                exit
            fi
            ;;
        *)
            cat << "_EOF"
------------------------------------------------------
We Only Support Linux And Mac So Far
------------------------------------------------------
_EOF
            exit
            ;;
    esac
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

    $execPrefix make install
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

reAssembleJDK() {
    cat << "_EOF"
------------------------------------------------------
Re-assemble Jdk Using Linux split & cat
------------------------------------------------------
_EOF
    jdkSliceDir=$mainWd/packages/jdk-splits
    slicePrefix=jdk-8u172-linux-x64
    jdkTarName=${slicePrefix}.tar.gz

    cd $pktPath
    if [[ -f "$jdkTarName" ]]; then
        echo [Warning]: Already has JDK re-assembled, skip
        return
    fi
    # check if re-assemble successfully
    cat $jdkSliceDir/${slicePrefix}a* > $jdkTarName
    if [[ $? != 0 ]]; then
        echo [Error]: cat JDK tar.gz error, quiting now
        exit
    fi
    cat << "_EOF"
------------------------------------------------------
Checking the Shasum of Jdk
------------------------------------------------------
_EOF
    shasumPath=`which sha256sum 2> /dev/null`
    if [[ $shasumPath == "" ]]; then
        return
    fi
    checkSumPath=../template/jdk.checksum
    if [[ ! -f ${checkSumPath} ]]; then
        echo [Error]: missing jdk checksum file, default match
        return
    fi
    ret=$(sha256sum --check $checkSumPath)
    checkRet=$(echo $ret | grep -i ok 2> /dev/null)
    if [[ "$checkRet" == "" ]]; then
        echo [FatalError]: jdk checksum failed
        exit 255
    fi
}

installJava8() {
    cat << "_EOF"
------------------------------------------------------
Installing Java version 8
------------------------------------------------------
_EOF
    javaPath=$javaInstDir/bin/java
    if [[ -x $javaPath ]]; then
        # already has java 8 installed
        return
    fi
    # tackle to install java8
    JAVA_HOME=$javaInstDir
    jdkVersion=jdk-8u172-linux-x64
    tarName=${jdkVersion}.tar.gz

    $execPrefix rm -rf $javaInstDir
    $execPrefix mkdir -p $javaInstDir
    cd $pktPath
    $execPrefix tar -zxv -f $tarName --strip-components=1 -C $javaInstDir
    # check if returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: untar java package error, quitting now
        exit
    fi

    # javaPath=$javaInstDir/bin/java already defined at top
    if [[ ! -x $javaPath ]]; then
        echo [Error]: java install error, quitting now
        exit
    fi
    # change owner of java install directory to root:root
    $execPrefix chown -R root:root $javaInstDir

    javaVersion=$($javaPath -version)
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
    $execPrefix cp $srvXmlTemplate $serverXmlPath

    # change listen port if not the default value, passed as $1
    if [[ "$1" != "" && "$1" != 8080 ]]; then
        newListenPort=$1
        cat << _EOF
------------------------------------------------------
Changing Listen Port from Default 8080 to $newListenPort
------------------------------------------------------
_EOF
        $execPrefix sed -i --regexp-extended \
            "s/(<Connector port=)\"8080\"/\1\"${newListenPort}\"/" \
            $serverXmlPath
        # check if returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: change listen port failed, quitting now
            exit
        fi
    fi
}

installTomcat8() {
    cat << "_EOF"
------------------------------------------------------
Installing Tomcat version 8
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

    # wgetLink=http://www-eu.apache.org/dist/tomcat/tomcat-8/v8.5.27/bin
    tomcatVersion=apache-tomcat-8.5.31
    tarName=${tomcatVersion}.tar.gz

    cd $pktPath
    # untar into /opt/tomcat and strip one level directory
    if [[ ! -d $tomcatInstDir ]]; then
        $execPrefix mkdir -p $tomcatInstDir
        $execPrefix tar -zxv -f $tarName --strip-components=1 -C $tomcatInstDir
    fi
    # check if untar returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: untar tomcat package error, quitting now
        exit
    fi

    # change owner:group of TOMCAT_HOME
    $execPrefix chown -R $tomcatUser:$tomcatGrp $tomcatInstDir
    cd $tomcatInstDir
    $execPrefix chmod 775 conf
    $execPrefix chmod g+r conf/*

    # change listen port if not the default value, passed as $1
    changeListenPort $1

    # make daemon script to start/stop Tomcat
    cd $mainWd
    # template script to copy from
    sptCopyFrom=./template/daemon.sh
    # rename this script to
    daeName=daemon.sh
    if [[ ! -f $daeName ]]; then
        cp $sptCopyFrom $daeName
        # add source command at top of script daemon.sh
        sed -i "2a source ${mainWd}/${dynamicEnvName}" $daeName
    fi
    # check if returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make daemon.sh error, quitting now
        exit
    fi

    cat << _EOF
------------------------------------------------------
Start to Compiling Jsvc
------------------------------------------------------
_EOF
    $execPrefix chmod 755 $tomcatInstDir/bin
    cd $tomcatInstDir/bin
    jsvcTarName=commons-daemon-native.tar.gz
    jsvcUntarName=commons-daemon-1.1.0-native-src
    # jsvcUntarName=commons-daemon-1.0.15-native-src
    if [[ ! -f $jsvcTarName ]]; then
        echo [Error]: $jsvcTarName not found, wrong tomcat package downloaded
        exit
    fi
    if [[ ! -d $jsvcUntarName ]]; then
        $execPrefix tar -zxv -f $jsvcTarName
    fi
    $execPrefix chmod -R 777 $jsvcUntarName

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

    $execPrefix cp jsvc ${tomcatInstDir}/bin
    # jsvcPath=$tomcatInstDir/bin/jsvc
    ls -l $jsvcPath
    if [[ $? != 0 ]]; then
        echo [Error]: check jsvc path error, quitting now
        exit
    fi
    # change owner of jsvc
    cd $tomcatInstDir/bin
    $execPrefix chown -R $newUser:$newGrp jsvc
    # remove jsvc build dir
    $execPrefix rm -rf $jsvcUntarName
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
    $execPrefix ls -l $sourceWarPath 2> /dev/null
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
    if [[ "$OpenGrokDeployMethod" == "wrapper" ]]; then
        buildPythonTools
    fi

    # OpenGrokDeployMethod: [wrapper | manual]
    deployOpenGrok

    # fix one warning
    $execPrefix mkdir -p ${opengrokInstanceBase}/{src,data,etc}
    $execPrefix cp -f $downloadPath/$OpenGrokUntarName/doc/logging.properties \
                 ${opengrokInstanceBase}/logging.properties
    # mkdir opengrok SRC_ROOT if not exist
    $execPrefix mkdir -p $opengrokSrcRoot
    srcRootUser=`whoami 2> /dev/null`
    if [[ '$srcRootUser' != '' && ! -f "$mRunFlagFile" ]]; then
        $execPrefix chown -R $srcRootUser $opengrokSrcRoot
        $execPrefix chown -R $srcRootUser $opengrokInstanceBase
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
    opengrokIndexerPath=`which opengrok-indexer 2> /dev/null`
    if [[ "$opengrokIndexerPath" == "" ]]; then
        echo [Warning]: No opengrok-indexer found, nothing matter
    fi

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
# The indexer can be run either using opengrok.jar directly:
$javaIndexerCommand
_EOF
    if [[ "$OpenGrokDeployMethod" == "wrapper" ]]; then
        cat << _EOF >> $callIndexerFilePath
# or using the opengrok-indexer wrapper like so:
# $wrapperIndexerCommand
_EOF
    fi
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
        $execPrefix $pythonDeployBinPath -c $configPath \
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
            echo copy $warPrefix.war to tomcat failed
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
Building OpenGrok Python Tools -- New Method
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
        $execPrefix python3 -m pip install opengrok-tools.tar.gz
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
_EOF
    if [[ $platCategory == "linux" ]]; then
        echo jsvc path = $jsvcPath >> $summaryTxt
    fi
    cat >> $summaryTxt << _EOF
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
    if [[ $platCategory == "mac" ]]; then
        catalina stop 2> /dev/null
    else
        sudo ./daemon.sh stop
        retVal=$?
        # just print warning
        if [[ $retVal != 0 ]]; then
            set +x
            cat << _EOF
[Warning]: daemon stop returns value: $retVal
_EOF
            # loop to kill tomcat living threads if daemon method failed
            for (( i = 0; i < 2; i++ )); do
                # root   70057  431  0.1 38846760 318236 pts/39 Sl  05:36   0:08 jsvc.
                tomcatThreads=`ps aux | grep -i tomcat | grep -i jsvc.exec | tr -s " " \
                    | cut -d " " -f 2`
                if [[ "$tomcatThreads" != "" ]]; then
                    $execPrefix kill -15 $tomcatThreads
                    if [[ $? != 0 ]]; then
                        echo [Error]: Stop Tomcat failed $(echo $1 + 1 | bc) time
                        sleep 1
                        continue
                    fi
                else
                    break
                fi
            done
            set -x
        fi
    fi
    cat << _EOF
--------------------------------------------------------
Start Tomcat Web Service
--------------------------------------------------------
_EOF
    sleep 1
    if [[ $platCategory == "mac" ]]; then
        catalina start
    else
        # try some times to start tomcat web service
        $execPrefix ./daemon.sh start
    fi

    retVal=$?
    # just print warning
    if [[ $retVal != 0 ]]; then
        cat << _EOF
[Warning]: daemon start returns value: $retVal
_EOF
    fi
}

preInstallForMac() {
    cat << _EOF
--------------------------------------------------------
Pre Install for Mac
--------------------------------------------------------
_EOF
    # brew cask remove caskroom/versions/java8
    if [[ ! -f $mRunFlagFile ]]; then
        brew cask install caskroom/versions/java8
        # check if java was successfully installed
        if [[ $? != 0 ]]; then
            cat << _EOF
If your Java application still asks for JRE installation, you might need
to reboot or logout/login.
_EOF
            exit 255
        fi
        brew install tomcat
        touch $mRunFlagFile
    fi
    # additional for 'wrapper' mode
    if [[ "$OpenGrokDeployMethod" == "wrapper" && "python3Path" == "" ]]; then
        brew install python3
        pip3 install --upgrade pip
    fi

    # set proper env
    javaInstDir=$(/usr/libexec/java_home -v 1.8)
    javaPath=`which java 2> /dev/null`
    tomcatInstPDir=/usr/local/Cellar/tomcat
    instVersion=`cd $tomcatInstPDir && ls | sort -r | head -n 1`
    # such as /usr/local/Cellar/tomcat/9.0.8
    tomcatInstDir=$tomcatInstPDir/$instVersion/libexec
    serverXmlPath=${tomcatInstDir}/conf/server.xml
    tomcatUser=`whoami`
    tomcatGrp='staff'
}

preInstallForLinux() {
    cat << _EOF
--------------------------------------------------------
Pre Install Tools for Linux
--------------------------------------------------------
_EOF
    if [[ "$OpenGrokDeployMethod" == "wrapper" && "python3Path" == "" ]]; then
        if [[ "$platOsType" == "ubuntu" ]]; then
            sudo apt-get install python3 -y
        elif [[ "$platOsType" == "centos" ]]; then
            sudo yum install python3 -y
        fi
    fi
}

install() {
    mkdir -p $downloadPath
    mkdir -p $loggingPath

    # check platform OS type first
    checkPlatOsType
    if [[ "$platOsType" == "macos" ]]; then
        # platform category is Mac
        platCategory=mac
        preInstallForMac
    else
        # platform category is Linux
        platCategory=linux
        preInstallForLinux
        # install java & tomcat
        reAssembleJDK
        installJava8
        installTomcat8
    fi

    # begin of common install part
    changeListenPort $1
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
