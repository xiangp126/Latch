#!/bin/bash
# From which path it was executed

# Open Debug
set -x

startDir=`pwd`
# Absolute path of this shell, no impact by start dir
mainWd=$(cd $(dirname $0); pwd)
logDir=$mainWd/log
logFile=$logDir/rsync.log
rsyncConfig=$mainWd/rsync.config
# empty or root
execPrefix=""

PATH=$HOME/.usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
if [[ ! -f $rsyncConfig ]]; then
    cat << "_EOF"
[Error]: missing rsync config file, you can add one refer ./template/rsync.config
step 1: cp ./template/rsync.config .
step 2: vim rsync.config
_EOF
    exit 1
fi

dynamicEnvPath=$mainWd/dynamic.env
source $dynamicEnvPath

if [[ ! -d $logDir ]]; then
    mkdir -p $logDir
fi

source $rsyncConfig

cd $OPENGROK_SRC_ROOT
rsync -azP "-e ssh -p ${SSHPORT}" ${SSHUSER}@${SERVER}:${SRCDIR_ON_SERVER}/ .

cd $logDir
$execPrefix $OPENGROK_BIN_PATH index
