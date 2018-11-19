#!/bin/bash
# Open Debug
set -x
startDir=`pwd`
# absolute path of this shell, not influenced by start dir
mainWd=$(cd $(dirname $0); pwd)
loggingPath=$mainWd/log
logFile=$loggingPath/rsync.log
rsyncConfig=$mainWd/rsync.config
# empty or root
# execPrefix=""

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

if [[ ! -d $loggingPath ]]; then
    mkdir -p $loggingPath
fi

# rcync source codes for indexing with remote server
source $rsyncConfig
cd $OPENGROK_SRC_ROOT
rsync -azP "-e ssh -p ${SSHPORT}" ${SSHUSER}@${SERVER}:${SRCDIR_ON_SERVER}/ .
if [[ $? != 0 ]]; then
    echo rsync with remote server failed
    exit 3
fi

# call indexer
cd $mainWd
./callIndexer
