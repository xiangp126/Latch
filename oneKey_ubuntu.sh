# For Ubuntu
# 1. Jdk 11 apt-get install
# 2. Tomcat 10 Manual compile and install
# 3. Universal ctags Manual compile and install
#!/bin/bash

# Misc Info
catBanner="---------------------------------------------------"
catBanner=$(echo "$catBanner" | sed 's/------/------ /g')
beautifyGap1="-> "
beautifyGap2="   "
beautifyGap3="♣  "
mainWd=$(cd $(dirname $0); pwd)
makeJobs=8
commInstdir=/opt
downloadPath=$mainWd/downloads
loggingPath=$mainWd/log
summaryTxt=$mainWd/summary.txt
systemSrcRoot=/opt/src

# Universal Ctags Info
uCtagsInstDir=$commInstdir/uctags

# Jdk Info - apt-get
jdkSystemInstalledVersion=openjdk-11-jdk
jdkInstDir=/usr/lib/jvm/java-11-openjdk-amd64
javaInstDir=$jdkInstDir
javaPath=$javaInstDir/bin/java
JAVA_HOME=$javaInstDir

# Tomcat Info
tomcatVersion=10.1.13
TOMCAT_HOME=$commInstdir/tomcat
CATALINA_HOME=$TOMCAT_HOME
tomcatInstDir=$TOMCAT_HOME
tomcatUser=tomcat
tomcatGrp=tomcat
setEnvFileName=setenv.sh
setEnvFilePath=$CATALINA_HOME/bin/$setEnvFileName
catalinaShellPath=$tomcatInstDir/bin/catalina.sh
catalinaPIDFile=$tomcatInstDir/temp/tomcat.pid
catalinaGetVerCmd=$tomcatInstDir/bin/version.sh
# serverXmlPath=${tomcatInstDir}/conf/server.xml
# srvXmlTemplate=$mainWd/template/server.xml

# OpenGrok Info
openGrokVersion=1.12.12
openGrokInstDir=$commInstdir/opengrok
openGrokTarName=opengrok-$openGrokVersion.tar.gz
openGrokUntarDir=opengrok-$openGrokVersion
openGrokPath=$downloadPath/$openGrokUntarDir
# OpenGrok Indexer Info
openGrokInstanceBase=$openGrokInstDir
openGrokSrcRoot=$openGrokInstanceBase/src
indexerFileName=call_indexer.sh
indexerFilePath=$mainWd/$indexerFileName
# The default listen port is 8080
defaltListenPort=8080
newListenPort=8080

logo() {
    cat << "_EOF"
  ___  _ __   ___ _ __   __ _ _ __ ___ | | __
 / _ \| '_ \ / _ \ '_ \ / _` | '__/ _ \| |/ /
| (_) | |_) |  __/ | | | (_| | | | (_) |   <
 \___/| .__/ \___|_| |_|\__, |_|  \___/|_|\_\
      |_|               |___/

_EOF
}

preInstallForUbuntu() {
    cat << _EOF
$catBanner
Pre Install Tools for Ubuntu
_EOF

sudo apt-get update
sudo apt-get install -y \
        pkg-config libevent-dev build-essential cmake \
        automake curl autoconf libtool python3 net-tools
}

installuCtags() {
    cat << _EOF
$catBanner
Installing Universal Ctags
_EOF
    # Check if the 'ctags' command is available
    if command -v ctags &> /dev/null; then
        # Check if 'ctags' is Universal Ctags
        if ctags --version | grep -i -q 'universal'; then
            uCtagsBinPath=`which ctags`
            echo "$beautifyGap1 Universal Ctags is already installed at: $uCtagsBinPath"
            $uCtagsBinPath --version
            return
        else
            echo "ctags is already installed, but it is not Universal Ctags."
            sudo apt-get remove exuberant-ctags -y
        fi
    fi

    if [[ ! -d $uCtagsInstDir ]]; then
        sudo mkdir -p $uCtagsInstDir
    fi

    cd $downloadPath
    local clonedName=ctags
    if [[ -d "$clonedName" ]]; then
        echo "Directory $clonedName already exist. Skipping git clone."
    else
        git clone https://github.com/universal-ctags/ctags
        if [[ $? != 0 ]]; then
            echo [Error]: git clone error, quitting now
            exit 255
        fi
    fi

    cd $clonedName
    # pull the latest code
    git pull
    ./autogen.sh
    ./configure --prefix=$uCtagsInstDir
    make -j$makeJobs
    if [[ $? != 0 ]]; then
        echo [Error]: make error, quitting now
        exit 255
    fi

    sudo make install
    if [[ $? != 0 ]]; then
        echo [Error]: make install error, quitting now
        exit 255
    fi

    uCtagsBinPath=$uCtagsInstDir/bin/ctags
    # create a soft link to /bin/ctags
    sudo ln -sf $uCtagsBinPath /bin/ctags

    cat << _EOF
$catBanner
Ctags Path = /bin/bash -> $uCtagsBinPath
$($uCtagsBinPath --version)
_EOF
}

installJdk() {
    cat << _EOF
$catBanner
Installing JDK
_EOF
    if [[ -x $javaPath ]]; then
        echo "$beautifyGap1 JDK is already installed at: $javaInstDir"
        $javaPath --version
        return
    fi
    sudo apt-get install $jdkSystemInstalledVersion -y

    cat << _EOF
$catBanner
Java Package Install Path = $javaInstDir
Java Path = $javaPath
$($javaPath -version)
_EOF
}

installTomcat() {
    cat << _EOF
$catBanner
Installing Tomcat 10
_EOF
    if [[ -x $catalinaGetVerCmd ]]; then
        echo "$beautifyGap1 Tomcat is already installed at: $tomcatInstDir"
        tomcatVerContext="$($catalinaGetVerCmd)"
        tomcatVersion=$(echo "$tomcatVerContext" | awk -F' ' '/Server number:/ {print $NF}')
        echo "$tomcatVerContext"
        echo "Tomcat Version = $tomcatVersion"
        return
    fi

    # Tomcat 10 binary in the official website always changes to the latest version
    # Define the baseUrl for Apache Tomcat 10 releases
    baseUrl="https://dlcdn.apache.org/tomcat/tomcat-10"

    # Fetch the HTML page containing the available versions
    htmlPage=$(curl -s "$baseUrl/")

    # Extract and print the latest version number from the HTML content
    # <a href="v10.1.13/">v10.1.13/</a>
    latestVersion=$(echo "$htmlPage" | grep -oP 'v\d+\.\d+\.\d+' | head -n 1)
    # v10.1.13 => 10.1.13
    tomcatVersion=$(echo "$latestVersion" | grep -oP '\d+\.\d+\.\d+')
    tomcatFullName=apache-tomcat-$tomcatVersion
    tomcatTarName=$tomcatFullName.tar.gz

    if [ -n "$latestVersion" ]; then
        # Construct the URL for the latest Tomcat 10 release binary
        tomcatUrl="$baseUrl/$latestVersion/bin/$tomcatTarName"

        cd $downloadPath
        # Download the latest Tomcat 10 release
        if [[ -f "$tomcatTarName" ]]; then
            echo "File $tomcatTarName already exist. Skipping download."
        else
            wget "$tomcatUrl"
        fi
    else
        echo "Failed to retrieve the latest Apache Tomcat version."
        exit 1
    fi

    # untar into /opt/tomcat and strip one level directory
    if [ ! -d "$tomcatInstDir" ] || [ -z "$(ls -A "$tomcatInstDir" 2>/dev/null)" ]; then
        if [[ ! -d $tomcatInstDir ]]; then
            sudo mkdir -p $tomcatInstDir
        fi
        sudo tar -zxv -f $tomcatTarName --strip-components=1 -C $tomcatInstDir
        if [[ $? != 0 ]]; then
            echo [Error]: untar tomcat package error, quitting now
            exit
        fi
    else
        echo "Directory $tomcatInstDir already exist and is not empty. Skipping untar"
    fi

    # change owner:group of TOMCAT_HOME
    tomcatOwner=`ls -ld $tomcatInstDir | awk '{print $3}'`
    if [[ "$tomcatOwner" == "$tomcatUser" ]]; then
        echo "Tomcat owner is already $tomcatUser, skipping chown"
    else
        sudo chown -R $tomcatUser:$tomcatGrp $tomcatInstDir
    fi

    local deployCheckPoint=$tomcatInstDir/webapps/
    if [ "$(stat -c %a $deployCheckPoint)" -eq 755 ]; then
        echo "Directory mod is already 755, skipping chmod"
    else
        sudo chmod -R 755 $tomcatInstDir
    fi

    # clear the temp dir in tomcat
    sudo rm -rf $tomcatInstDir/temp/*

    cat << _EOF
$catBanner
Tomcat Version Name = $tomcatFullName
Tomcat Install Path = $tomcatInstDir
_EOF
}

installOpenGrok() {
    cat << _EOF
$catBanner
Installing OpenGrok v$openGrokVersion
_EOF
    local downBaseUrl=https://github.com/oracle/opengrok/releases/download/
    downloadUrl=$downBaseUrl/$openGrokVersion/$openGrokTarName

    cd $downloadPath
    # check if already has tar ball downloaded
    if [[ -f $openGrokTarName ]]; then
        echo "File $openGrokTarName already exist. Skipping download."
    else
        wget --no-cookies \
             --no-check-certificate \
             --header "Cookie: oraclelicense=accept-securebackup-cookie" \
             "$downloadUrl" \
             -O $openGrokTarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo "wget $downloadUrl failed, quitting now"
            exit 1
        fi
    fi

    if [[ ! -d $openGrokUntarDir ]]; then
        tar -zxvf $openGrokTarName
    else
        echo "Directory $openGrokUntarDir already exist. Skipping untar."
    fi

    # Info about OpenGrok Web Application
    local warFileName=source.war
    warFilePath=$openGrokUntarDir/lib/$warFileName
    cd $openGrokUntarDir

    # If user does not use default OPENGROK_INSTANCE_BASE then attempt to
    # extract WEB-INF/web.xml from source.war using jar or zip utility, update
    # the hardcoded values and then update source.war with the new
    # WEB-INF/web.xml.
    if [[ "$openGrokInstanceBase" != "/var/opengrok" ]]; then
        cd lib
        if [[ ! -f $warFileName ]]; then
            echo "File $warFileName does not exist, quitting now"
            exit 2
        fi
        # Extract and overwrite the WEB-INF/web.xml file from source.war archive.
        unzip -o $warFileName WEB-INF/web.xml

        # Change the hardcoded values in WEB-INF/web.xml
        cd WEB-INF
        local webXmlName=web.xml
        local changeFrom=/var/opengrok/etc/configuration.xml
        local changeTo=$openGrokInstanceBase/etc/configuration.xml
        if grep -q "$changeTo" "$webXmlName"; then
            echo "WEB-INF/web.xml already updated, skipping sed and zip -u"
        else
            # update web.xml
            sed -i -e 's:'"$changeFrom"':'"$changeTo"':g' "$webXmlName"
            cd ..
            zip -u source.war WEB-INF/web.xml &>/dev/null
        fi
    fi

    # copy source.war to tomcat webapps
    tomcatWebAppsDir=$tomcatInstDir/webapps
    cd $downloadPath
    sudo cp -f $warFilePath $tomcatWebAppsDir
    if [[ $? != 0 ]]; then
        echo "copy $warPath to $tomcatWebAppsDir failed, quitting now"
        exit 2
    fi

    sudo mkdir -p ${openGrokInstanceBase}/{data,dist,etc,log}

    # check if $systemSrcRoot is exist, if no then create it
    if [[ ! -d $systemSrcRoot ]]; then
        sudo mkdir -p $systemSrcRoot
    fi

    # make a soft link to /opt/src
    if [[ -L $openGrokSrcRoot ]]; then
        echo "$beautifyGap3 Soft link $openGrokSrcRoot already exist. Skipping ln -sf"
    else
        sudo ln -sf $systemSrcRoot $openGrokSrcRoot
    fi

    # fix one warning
    sudo cp -f $downloadPath/$openGrokUntarDir/doc/logging.properties \
               ${openGrokInstanceBase}/etc

}

callIndexer() {
    local loggingPropertyFile=$openGrokInstanceBase/etc/logging.properties
    javaIndexerCommand=$(echo $javaPath \
        -Djava.util.logging.config.file=$loggingPropertyFile \
        -jar $openGrokPath/lib/opengrok.jar \
        -c $uCtagsBinPath \
        -s $openGrokSrcRoot \
        -d $openGrokInstanceBase/data -H -P -S -G \
        -W $openGrokInstanceBase/etc/configuration.xml)

    makeIndexerFile

    # The indexer will generate opengrok0.0.log at the same directory
    # But I'd like it to generate log file at $loggingPath
    if [[ ! -d $loggingPath ]]; then
        mkdir -p $loggingPath
    fi

    cd $loggingPath
    cat << _EOF
$catBanner
Calling the Indexer
_EOF
    sudo $javaIndexerCommand

    if [[ $? != 0 ]]; then
        echo "Indexing failed, quitting now"
        exit 1
    fi
}

# save indexer commands into a shell
makeIndexerFile() {
    cat << _EOF
$catBanner
Saving Indexer Commands into $indexerFileName
_EOF

    cat << _EOF > $indexerFilePath
#/bin/bash
set -x
cd $loggingPath
sudo $javaIndexerCommand
sudo lsof -i :$newListenPort
if [[ \$? == 0 ]]; then
    sudo $catalinaShellPath stop -force
fi
sudo $catalinaShellPath start

_EOF
    chmod +x $indexerFilePath

    # make a soft link to /bin/callIndexer
    if [[ -L /bin/callIndexer ]]; then
        echo "$beautifyGap3 Soft link /bin/callIndexer already exist. Skipping ln -sf"
    else
        sudo ln -sf $indexerFilePath /bin/callIndexer
    fi
}

summaryInfo() {
    cat > $summaryTxt << _EOF
Universal Ctags Path = $uCtagsBinPath
Java Home = $javaInstDir
Java Path = $javaPath
Tomcat Home = $tomcatInstDir
Tomcat Version = $tomcatVersion
Opengrok Instance Base = $openGrokInstanceBase
Opengrok Source Root = $openGrokSrcRoot => $systemSrcRoot
Indexer File: $indexerFilePath
Server at: http://127.0.0.1:${newListenPort}/source
_EOF

cat << _EOF
$catBanner
$(cat $summaryTxt)
_EOF
# Print the logo
logo
}

setEnv() {
    cat << _EOF
$catBanner
Setting Environment Variables for Catalina/Tomcat
_EOF
    cat << _EOF | sudo tee $setEnvFilePath
#!/bin/bash
export JAVA_HOME=${JAVA_HOME}
export JRE_HOME=${JAVA_HOME}
export CLASSPATH=${JAVA_HOME}/lib:${JRE_HOME}/lib
export TOMCAT_USER=${tomcatUser}
export TOMCAT_HOME=${TOMCAT_HOME}
export CATALINA_HOME=${TOMCAT_HOME}
export CATALINA_BASE=${TOMCAT_HOME}
export CATALINA_TMPDIR=${TOMCAT_HOME}/temp
export CATALINA_PID=${catalinaPIDFile}
export OPENGROK_INSTANCE_BASE=${openGrokInstanceBase}
export OPENGROK_TOMCAT_BASE=$CATALINA_HOME
export OPENGROK_SRC_ROOT=$openGrokSrcRoot
export OPENGROK_CTAGS=$uCtagsBinPath
export UCTAGS_INSTALL_DIR=$uCtagsInstDir
_EOF
    # make it executable
    sudo chmod +x $setEnvFilePath
}

startTomcat() {
    cd $mainWd
    cat << _EOF
$catBanner
Checking if Tomcat is running
_EOF
    sudo lsof -i :$newListenPort
    if [[ $? == 0 ]]; then
        echo "$beautifyGap1 Tomcat is running, stopping it now"
        sudo $catalinaShellPath stop -force
    else
        echo "$beautifyGap1 Tomcat is not running"
    fi

    echo "$beautifyGap1 Starting Tomcat now"
    sudo $catalinaShellPath start
}

install() {
    if [[ ! -d $downloadPath ]]; then
        mkdir -p $downloadPath
    fi

    if [[ ! -d $loggingPath ]]; then
        mkdir -p $loggingPath
    fi

    # preInstallForUbuntu
    installuCtags
    installJdk
    installTomcat
    installOpenGrok
    callIndexer
    setEnv
    startTomcat
    summaryInfo
}

install
