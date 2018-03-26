#!/bin/bash
# where is shell executed
startDir=`pwd`
# main work directory, not influenced by start dir
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
OPENGROKPATH=""
# new user/group to run tomcat
tomcatUser=tomcat8
tomcatGrp=tomcat8
# store install summary
summaryTxt=INSTALLATION.TXT
# store all downloaded packages here
downloadPath=$mainWd/downloads
# store JDK/Tomcat packages
pktPath=$mainWd/packages

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
    sh $exeName -- setup OpenGrok through one key stroke

[SYNOPSIS]
    sh $exeName [install | summary | help] [PORT]

[EXAMPLE]
    sh $exeName [help]
    sh $exeName install
    sh $exeName install 8081
    sh $exeName summary

[DESCRIPTION]
    install -> install opengrok, need root privilege but no sudo prefix
    help    -> print help page
    summary -> print tomcat/opengrok guide and installation info

[TIPS]
    Default listen-port is $newListenPort if [PORT] was omitted

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
INSTALLING UNIVERSAL CTAGS
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

installGitLfs() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING GIT-LFS
------------------------------------------------------
_EOF
    gitLfsInstDir=/usr/local
    gitLfsPath=$gitLfsInstDir/bin/git-lfs
    if [[ -x "$gitLfsPath" ]]; then
        echo [Warning]: Already has git-lfs installed, skip
        return
    fi
    wgetLink=https://github.com/git-lfs/git-lfs/releases/download/v2.4.0
    tarName=git-lfs-linux-amd64-2.4.0.tar.gz
    untarName=git-lfs-2.4.0

    # tackle install git-lfs
    cd $downloadPath
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exist
    else
        wget --no-cookies \
             --no-check-certificate \
             --header "Cookie: oraclelicense=accept-securebackup-cookie" \
             "${wgetLink}/${tarName}" \
             -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget error, quiting now
            exit
        fi
    fi
    if [[ ! -d $untarName ]]; then
        tar -zxv -f $tarName
    fi
    cd $untarName
    $execPrefix cp -f git-lfs $gitLfsInstDir/bin

    # download real packages before install JDK/Tomcat
    git lfs pull

    cat << _EOF
------------------------------------------------------
git-lfs install path = $gitLfsPath
------------------------------------------------------
_EOF
}

installJava8() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING JAVA 8
------------------------------------------------------
_EOF
    javaPath=$javaInstDir/bin/java
    if [[ -x $javaPath ]]; then
        echo "[Warning]: already has java 8 installed"
        return
    fi
    # tackle to install java8
    JAVA_HOME=$javaInstDir
    # wgetLink=http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808
    tarName=jdk-8u161-linux-x64.tar.gz
    # untarName=jdk1.8.0_161

    cd $pktPath
    # rename download package
    if [[ ! -d $javaInstDir ]]; then
        $execPrefix mkdir -p $javaInstDir
        $execPrefix tar -zxv -f $tarName --strip-components=1 -C $javaInstDir
        # check if returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: untar java package error, quitting now
            exit
        fi
    fi
    # javaPath=$javaInstDir/bin/java already defined at top
    if [[ ! -x $javaPath ]]; then
        echo [Error]: java install error, quitting now
        exit
    fi
    cat << _EOF
------------------------------------------------------
java package install path = $javaInstDir
java path = $javaPath
$($javaPath -version)
------------------------------------------------------
_EOF
}

changeListenPort() {
    # change listen port if not the default value, passed as $1
    if [[ "$1" != "" && "$1" != 8080 ]]; then
        newListenPort=$1
        cat << _EOF
------------------------------------------------------
CHANGING DEFAULT LISTEN PORT 8080 TO $newListenPort
------------------------------------------------------
_EOF
        $execPrefix sed -i --regexp-extended \
            "s/(<Connector port=)\"8080\"/\1\"${newListenPort}\"/" \
            $serverXmlPath
        # check if returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: change listen port error, quitting now
            exit
        fi
    fi
}

installTomcat8() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING TOMCAT 8
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
        # srvXmlTemplate=$mainWd/template/server.xml
        $execPrefix cp $srvXmlTemplate $serverXmlPath

        # change listen port if not the default value, passed as $1
        changeListenPort $1
        return
    fi

    # run tomcat using newly made user: tomcat:tomcat
    newUser=$tomcatUser
    newGrp=$tomcatGrp
    # create group if not exist
    egrep "^$newGrp" /etc/group &> /dev/null
    if [[ $? = 0 ]]; then
        echo [Warning]: group $newGrp already exist
    else
        $execPrefix groupadd $newUser
    fi
    # create user if not exist
    egrep "^$newUser" /etc/passwd &> /dev/null
    if [[ $? = 0 ]]; then
        echo [Warning]: group $newGrp already exist
    else
        $execPrefix useradd -s /bin/false -g $newGrp -d $tomcatInstDir $newUser
    fi

    # begin download routine
    # wgetLink=http://www-eu.apache.org/dist/tomcat/tomcat-8/v8.5.27/bin
    tarName=apache-tomcat-8.5.27.tar.gz

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
    $execPrefix chown -R $newUser:$newGrp $tomcatInstDir
    cd $tomcatInstDir
    $execPrefix chmod 775 conf
    $execPrefix chmod g+r conf/*

    # change listen port if not the default value, passed as $1
    changeListenPort $1

    # make daemon script to start/shutdown Tomcat
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
START TO COMPILING JSVC
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
export OPENGROK_CTAGS=$uCtagsPath
_EOF
    # do not parse value of $var
    cat >> $dynamicEnvName << "_EOF"
export PATH=${JAVA_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
_EOF
    chmod +x $dynamicEnvName
}

# deploy OpenGrok
installOpenGrok() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING OPENGROK
------------------------------------------------------
_EOF
    wgetLink=https://github.com/oracle/opengrok/releases/download/1.1-rc21
    tarName=opengrok-1.1-rc21.tar.gz
    untarName=opengrok-1.1-rc21

    cd $downloadPath
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exist
    else
        wget --no-cookies \
             --no-check-certificate \
             --header "Cookie: oraclelicense=accept-securebackup-cookie" \
             "${wgetLink}/${tarName}" \
             -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget error, quiting now
            exit
        fi
    fi

    if [[ ! -d $untarName ]]; then
        tar -zxv -f $tarName
    fi
    cat << _EOF
------------------------------------------------------
MAKEING DYNAMIC ENVIRONMENT FILE FOR SOURCE
------------------------------------------------------
_EOF
    # call func makeDynEnv
    makeDynEnv

    # enter into opengrok downloaded dir
    cd $downloadPath
    cd $untarName/bin
    # OpenGrok executable file name is OpenGrok
    ogExecFile=OpenGrok
    # add write privilege to it.
    chmod +w $ogExecFile
    OPENGROKPATH=`pwd`

    # add source command on top of script OpenGrok
    # delete already command at first
    # notice double quotation marks
    sed -i '/^source.*env$/d' OpenGrok 2> /dev/null
    sed -i "2a source ${mainWd}/${dynamicEnvName}" OpenGrok
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
    cat > $summaryTxt << _EOF
TOMCAT STARTED SUCCESSFULLY
---------------------------------------- SUMMARY ----
universal ctags path = $uCtagsPath
git-lfs path = $gitLfsPath
java path = $javaPath
jsvc path = $jsvcPath
java home = $javaInstDir
tomcat home = $tomcatInstDir
opengrok instance base = $opengrokInstanceBase
opengrok source root = $opengrokSrcRoot
http://127.0.0.1:${newListenPort}/source
------------------------------------------------------
_EOF
    cat $summaryTxt
}

printHelpPage() {
    cat << _EOF
-------------------------------------------------
FOR TOMCAT 8 GUIDE
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
FOR OPENGROK GUIDE
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
-- GUIDE TO CHANGE LISTEN PORT
# replace s/original/8080/ to the port you want to change
sudo sed -i 's/${newListenPort}/8080/' $serverXmlPath
sudo ./daemon.sh stop
sudo ./daemon.sh start
------------------------------------------------------
_EOF
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
STOP TOMCAT DAEMON ALREADY RUNNING
--------------------------------------------------------
_EOF
    # not check exit status
    sudo ./daemon.sh stop
    retVal=$?
    #just print warning
    if [[ $retVal != 0 ]]; then
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
                    echo [Error]: Tomcat threads stop failed $(echo $1 + 1 | bc) time
                    sleep 1
                    continue
                fi
            else
                break
            fi
        done
    fi
    cat << _EOF
--------------------------------------------------------
START TOMCAT WEB SERVICE
--------------------------------------------------------
_EOF
    sleep 1
    # try some times to start tomcat web service
    $execPrefix ./daemon.sh start
    retVal=$?
    # just print warning
    if [[ $retVal != 0 ]]; then
        cat << _EOF
[Warning]: daemon start returns value: $retVal
_EOF
    fi
}

install() {
    mkdir -p $downloadPath
    installGitLfs
    installuCtags
    installJava8
    # $1 passed as new listen port
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

    "summary")
        set +x
        printHelpPage
        ;;

    *)
        set +x
        usage
        ;;
esac
